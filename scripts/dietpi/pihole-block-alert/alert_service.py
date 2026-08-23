#!/usr/bin/env python3

import collections
import os
import re
import selectors
import signal
import smtplib
import socket
import sqlite3
import ssl
import subprocess
import sys
import time
from datetime import datetime
from email.message import EmailMessage
from pathlib import Path

LOG_FILE = "/var/log/pihole/pihole.log"
DB_FILE = "/var/lib/pihole-block-alert/events.db"
WINDOW_SECONDS = 60
RETRY_SECONDS = 300
GRAVITY_DB = "/etc/pihole/gravity.db"
ALERT_ADLISTS = {
    2: "adult",
    3: "gambling",
    4: "bypass",
    5: "threat",
}
ALERT_PRIORITY = (5, 4, 2, 3)

QUERY_RE = re.compile(
    r"dnsmasq\[\d+\]: query\[(?P<qtype>[^\]]+)\] "
    r"(?P<domain>\S+) from (?P<client>\S+)"
)

BLOCK_RE = re.compile(
    r"dnsmasq\[\d+\]: "
    r"(?P<reason>gravity blocked|regex blocked|exactly blacklisted|"
    r"denylist blocked|special domain) "
    r"(?P<domain>\S+) is "
)

running = True
pending = collections.defaultdict(collections.deque)


def stop(_signum, _frame):
    global running
    running = False


def required_environment():
    required = (
        "SMTP_HOST",
        "SMTP_PORT",
        "SMTP_USERNAME",
        "SMTP_PASSWORD",
        "EMAIL_FROM",
        "EMAIL_TO",
    )
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError(
            "Missing environment variables: " + ", ".join(missing)
        )


def open_database():
    db = sqlite3.connect(DB_FILE)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=5000")

    db.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY,
            event_time INTEGER NOT NULL,
            event_time_iso TEXT NOT NULL,
            pihole_host TEXT NOT NULL,
            client TEXT NOT NULL,
            domain TEXT NOT NULL,
            query_type TEXT NOT NULL,
            block_reason TEXT NOT NULL
        )
    """)

    db.execute("""
        CREATE INDEX IF NOT EXISTS idx_events_time
        ON events(event_time)
    """)

    db.execute("""
        CREATE INDEX IF NOT EXISTS idx_events_client_domain
        ON events(client, domain, event_time)
    """)

    db.execute("""
        CREATE TABLE IF NOT EXISTS email_windows (
            id INTEGER PRIMARY KEY,
            client TEXT NOT NULL,
            domain TEXT NOT NULL,
            query_type TEXT NOT NULL,
            block_reason TEXT NOT NULL,
            first_event INTEGER NOT NULL,
            last_event INTEGER NOT NULL,
            send_after INTEGER NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 1,
            sent_at INTEGER,
            next_attempt INTEGER NOT NULL,
            last_error TEXT
        )
    """)

    db.commit()
    return db



def alert_category(domain):
    try:
        gravity = sqlite3.connect(
            f"file:{GRAVITY_DB}?mode=ro",
            uri=True,
            timeout=5,
        )
        rows = gravity.execute(
            """
            SELECT DISTINCT adlist_id
            FROM gravity
            WHERE domain = ?
            """,
            (domain,),
        ).fetchall()
        gravity.close()
    except sqlite3.Error as exc:
        print(
            f"Category lookup failed for {domain}: {exc}",
            file=sys.stderr,
            flush=True,
        )
        return None

    matched = {row[0] for row in rows}
    for adlist_id in ALERT_PRIORITY:
        if adlist_id in matched:
            return ALERT_ADLISTS[adlist_id]

    return None


def record_event(db, client, domain, qtype, reason):
    now = int(time.time())
    host = socket.gethostname()
    iso = datetime.now().astimezone().isoformat(timespec="seconds")

    db.execute(
        """
        INSERT INTO events (
            event_time, event_time_iso, pihole_host,
            client, domain, query_type, block_reason
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (now, iso, host, client, domain, qtype, reason),
    )

    category = alert_category(domain)

    if category is None:
        db.commit()
        print(
            f"Recorded without email: client={client} "
            f"domain={domain} reason={reason}",
            flush=True,
        )
        return

    reason = f"{category}: {reason}"

    current = db.execute(
        """
        SELECT id
        FROM email_windows
        WHERE client = ?
          AND domain = ?
          AND sent_at IS NULL
          AND ? <= send_after
        ORDER BY id DESC
        LIMIT 1
        """,
        (client, domain, now),
    ).fetchone()

    if current:
        db.execute(
            """
            UPDATE email_windows
            SET attempts = attempts + 1,
                last_event = ?,
                query_type = ?,
                block_reason = ?
            WHERE id = ?
            """,
            (now, qtype, reason, current[0]),
        )
    else:
        send_after = now + WINDOW_SECONDS
        db.execute(
            """
            INSERT INTO email_windows (
                client, domain, query_type, block_reason,
                first_event, last_event, send_after,
                attempts, next_attempt
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
            """,
            (
                client,
                domain,
                qtype,
                reason,
                now,
                now,
                send_after,
                send_after,
            ),
        )

    db.commit()


def send_email(row):
    (
        window_id,
        client,
        domain,
        qtype,
        reason,
        first_event,
        last_event,
        attempts,
    ) = row

    host = socket.gethostname()
    first_text = datetime.fromtimestamp(
        first_event
    ).astimezone().strftime("%d %B %Y %H:%M:%S %Z")
    last_text = datetime.fromtimestamp(
        last_event
    ).astimezone().strftime("%d %B %Y %H:%M:%S %Z")

    message = EmailMessage()
    message["From"] = os.environ["EMAIL_FROM"]
    message["To"] = os.environ["EMAIL_TO"]
    message["Subject"] = (
        f"[Pi-hole BLOCKED] {client} -> {domain}"
    )
    message.set_content(
        "Pi-hole blocked a DNS request.\n\n"
        f"Pi-hole: {host}\n"
        f"Client: {client}\n"
        f"Domain: {domain}\n"
        f"Query type: {qtype}\n"
        f"Block reason: {reason}\n"
        f"First attempt: {first_text}\n"
        f"Last attempt: {last_text}\n"
        f"Attempts in alert window: {attempts}\n"
        "Result: BLOCKED\n\n"
        "Note: a DNS request may be generated by a browser, "
        "application or background service and does not by itself "
        "prove that a person deliberately visited the domain."
    )

    context = ssl.create_default_context()
    with smtplib.SMTP(
        os.environ["SMTP_HOST"],
        int(os.environ["SMTP_PORT"]),
        timeout=30,
    ) as smtp:
        smtp.ehlo()
        smtp.starttls(context=context)
        smtp.ehlo()
        smtp.login(
            os.environ["SMTP_USERNAME"],
            os.environ["SMTP_PASSWORD"],
        )
        smtp.send_message(message)

    return window_id


def process_email_queue(db):
    now = int(time.time())
    rows = db.execute(
        """
        SELECT id, client, domain, query_type, block_reason,
               first_event, last_event, attempts
        FROM email_windows
        WHERE sent_at IS NULL
          AND send_after <= ?
          AND next_attempt <= ?
        ORDER BY id
        LIMIT 20
        """,
        (now, now),
    ).fetchall()

    for row in rows:
        try:
            window_id = send_email(row)
            db.execute(
                """
                UPDATE email_windows
                SET sent_at = ?, last_error = NULL
                WHERE id = ?
                """,
                (int(time.time()), window_id),
            )
            db.commit()
            print(
                f"Email sent: client={row[1]} domain={row[2]} "
                f"attempts={row[7]}",
                flush=True,
            )
        except Exception as exc:
            error = f"{type(exc).__name__}: {exc}"[:500]
            db.execute(
                """
                UPDATE email_windows
                SET next_attempt = ?, last_error = ?
                WHERE id = ?
                """,
                (int(time.time()) + RETRY_SECONDS, error, row[0]),
            )
            db.commit()
            print(
                f"Email failed for window {row[0]}: {error}",
                file=sys.stderr,
                flush=True,
            )


def cleanup_pending():
    cutoff = time.time() - 30
    empty = []

    for domain, entries in pending.items():
        while entries and entries[0][0] < cutoff:
            entries.popleft()
        if not entries:
            empty.append(domain)

    for domain in empty:
        pending.pop(domain, None)


def handle_line(db, line):
    query = QUERY_RE.search(line)
    if query:
        domain = query.group("domain").lower().rstrip(".")
        pending[domain].append(
            (
                time.time(),
                query.group("client"),
                query.group("qtype"),
            )
        )
        return

    blocked = BLOCK_RE.search(line)
    if not blocked:
        return

    domain = blocked.group("domain").lower().rstrip(".")
    reason = blocked.group("reason")

    if pending.get(domain):
        _seen, client, qtype = pending[domain].popleft()
        if not pending[domain]:
            pending.pop(domain, None)
    else:
        client = "unknown"
        qtype = "unknown"

    record_event(db, client, domain, qtype, reason)
    print(
        f"Recorded block: client={client} domain={domain} "
        f"type={qtype} reason={reason}",
        flush=True,
    )


def main():
    required_environment()
    db = open_database()

    tail = subprocess.Popen(
        ["tail", "-n", "0", "-F", LOG_FILE],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    selector = selectors.DefaultSelector()
    selector.register(tail.stdout, selectors.EVENT_READ)

    try:
        while running:
            ready = selector.select(timeout=2)

            for key, _mask in ready:
                line = key.fileobj.readline()
                if line:
                    handle_line(db, line)

            cleanup_pending()
            process_email_queue(db)

            if tail.poll() is not None:
                raise RuntimeError(
                    f"tail process stopped with status {tail.returncode}"
                )
    finally:
        tail.terminate()
        try:
            tail.wait(timeout=5)
        except subprocess.TimeoutExpired:
            tail.kill()
        db.close()


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    main()
