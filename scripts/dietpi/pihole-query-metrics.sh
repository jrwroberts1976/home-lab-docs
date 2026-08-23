#!/usr/bin/env bash
set -euo pipefail

HOST="dietpi"

DB="/etc/pihole/pihole-FTL.db"
GRAVITY="/etc/pihole/gravity.db"

OUT="/var/lib/prometheus/node-exporter/pihole_queries.prom"
TMP="${OUT}.tmp"

escape_label() {
    printf '%s' "$1" |
        sed 's/\\/\\\\/g; s/"/\\"/g'
}

{
echo '# HELP pihole_blocked_queries_total Total blocked queries retained in the Pi-hole query database.'
echo '# TYPE pihole_blocked_queries_total gauge'

sqlite3 "$DB" "
SELECT COUNT(*)
FROM queries
WHERE status IN (1,4,5,6,7,8,9,10,11,15,16,18);
" |
awk -v host="$HOST" \
    '{print "pihole_blocked_queries_total{host=\""host"\"} "$1}'

echo

echo '# HELP pihole_blocked_queries_7d Blocked Pi-hole queries during the last seven days.'
echo '# TYPE pihole_blocked_queries_7d gauge'

sqlite3 "$DB" "
SELECT COUNT(*)
FROM queries
WHERE status IN (1,4,5,6,7,8,9,10,11,15,16,18)
  AND timestamp >= strftime('%s','now','-7 days');
" |
awk -v host="$HOST" \
    '{print "pihole_blocked_queries_7d{host=\""host"\"} "$1}'

echo

echo '# HELP pihole_blocked_domain_hits_7d Blocked-domain hits during the last seven days.'
echo '# TYPE pihole_blocked_domain_hits_7d gauge'

sqlite3 -separator '|' "$DB" "
SELECT domain, COUNT(*) AS hits
FROM queries
WHERE status IN (1,4,5,6,7,8,9,10,11,15,16,18)
  AND timestamp >= strftime('%s','now','-7 days')
GROUP BY domain
ORDER BY hits DESC
LIMIT 50;
" |
while IFS='|' read -r domain hits
do
    domain="$(escape_label "$domain")"
    echo "pihole_blocked_domain_hits_7d{host=\"$HOST\",domain=\"$domain\"} $hits"
done

echo

echo '# HELP pihole_blocked_client_hits_7d Blocked queries by client during the last seven days.'
echo '# TYPE pihole_blocked_client_hits_7d gauge'

sqlite3 -separator '|' "$DB" "
SELECT client, COUNT(*) AS hits
FROM queries
WHERE status IN (1,4,5,6,7,8,9,10,11,15,16,18)
  AND timestamp >= strftime('%s','now','-7 days')
GROUP BY client
ORDER BY hits DESC;
" |
while IFS='|' read -r client hits
do
    client="$(escape_label "$client")"
    echo "pihole_blocked_client_hits_7d{host=\"$HOST\",client=\"$client\"} $hits"
done

echo

echo '# HELP pihole_blocked_client_last_timestamp_seconds Unix timestamp of the most recent blocked query for a client.'
echo '# TYPE pihole_blocked_client_last_timestamp_seconds gauge'

sqlite3 -separator '|' "$DB" "
SELECT client, CAST(MAX(timestamp) AS INTEGER)
FROM queries
WHERE status IN (1,4,5,6,7,8,9,10,11,15,16,18)
GROUP BY client;
" |
while IFS='|' read -r client timestamp
do
    client="$(escape_label "$client")"
    echo "pihole_blocked_client_last_timestamp_seconds{host=\"$HOST\",client=\"$client\"} $timestamp"
done

echo

echo '# HELP pihole_blocked_client_category_hits_7d Blocked queries by client and known blocking-list category during the last seven days.'
echo '# TYPE pihole_blocked_client_category_hits_7d gauge'

sqlite3 -separator '|' "$DB" "
ATTACH DATABASE '/var/lib/pihole-category-cache.db' AS cat;

SELECT
    q.client,
    c.category,
    COUNT(*) AS hits
FROM queries q
JOIN cat.category_domains c
  ON c.domain = lower(q.domain)
WHERE q.status IN (1,4,5,6,7,8,9,10,11,15,16,18)
  AND q.timestamp >= strftime('%s','now','-7 days')
  AND c.category IN ('adult','gambling','threat','bypass')
GROUP BY q.client, c.category
ORDER BY q.client, hits DESC;
" |
while IFS='|' read -r client category hits
do
    client="$(escape_label "$client")"
    category="$(escape_label "$category")"
    echo "pihole_blocked_client_category_hits_7d{host=\"$HOST\",client=\"$client\",category=\"$category\"} $hits"
done

echo

echo '# HELP pihole_blocked_client_category_last_timestamp_seconds Unix timestamp of the most recent blocked query for a client/category.'
echo '# TYPE pihole_blocked_client_category_last_timestamp_seconds gauge'

sqlite3 -separator '|' "$DB" "
ATTACH DATABASE '/var/lib/pihole-category-cache.db' AS cat;

SELECT
    q.client,
    c.category,
    CAST(MAX(q.timestamp) AS INTEGER)
FROM queries q
JOIN cat.category_domains c
  ON c.domain = lower(q.domain)
WHERE q.status IN (1,4,5,6,7,8,9,10,11,15,16,18)
  AND c.category IN ('adult','gambling','threat','bypass')
GROUP BY q.client, c.category;
" |
while IFS='|' read -r client category timestamp
do
    client="$(escape_label "$client")"
    category="$(escape_label "$category")"
    echo "pihole_blocked_client_category_last_timestamp_seconds{host=\"$HOST\",client=\"$client\",category=\"$category\"} $timestamp"
done
echo

echo '# HELP pihole_blocked_client_category_last_event_timestamp_seconds Unix timestamp of the most recent blocked query for a client/category, including domain.'
echo '# TYPE pihole_blocked_client_category_last_event_timestamp_seconds gauge'

sqlite3 -separator '|' "$DB" "
ATTACH DATABASE '/var/lib/pihole-category-cache.db' AS cat;

WITH matched AS (
    SELECT
        q.client,
        c.category,
        lower(q.domain) AS domain,
        CAST(q.timestamp AS INTEGER) AS timestamp
    FROM queries q
    JOIN cat.category_domains c
      ON c.domain = lower(q.domain)
    WHERE q.status IN (1,4,5,6,7,8,9,10,11,15,16,18)
      AND c.category IN ('adult','gambling','threat','bypass')
),
latest AS (
    SELECT
        client,
        category,
        MAX(timestamp) AS timestamp
    FROM matched
    GROUP BY client, category
)
SELECT
    m.client,
    m.category,
    MIN(m.domain) AS domain,
    l.timestamp
FROM matched m
JOIN latest l
  ON l.client = m.client
 AND l.category = m.category
 AND l.timestamp = m.timestamp
GROUP BY m.client, m.category, l.timestamp;
" |
while IFS='|' read -r client category domain timestamp
do
    client="$(escape_label "$client")"
    category="$(escape_label "$category")"
    domain="$(escape_label "$domain")"

    echo "pihole_blocked_client_category_last_event_timestamp_seconds{host=\"$HOST\",client=\"$client\",category=\"$category\",domain=\"$domain\"} $timestamp"
done

echo
echo

echo '# HELP pihole_block_metrics_timestamp_seconds Time Pi-hole query metrics were generated.'
echo '# TYPE pihole_block_metrics_timestamp_seconds gauge'
echo "pihole_block_metrics_timestamp_seconds{host=\"$HOST\"} $(date +%s)"

} > "$TMP"

sudo chown root:root "$TMP"
sudo chmod 644 "$TMP"
sudo mv "$TMP" "$OUT"
