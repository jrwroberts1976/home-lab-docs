#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from collections import Counter
from pathlib import Path


def prom_escape(value: str) -> str:
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace("\n", "\\n")
        .replace('"', '\\"')
    )


def run_trivy() -> dict:
    cmd = [
        "/usr/local/bin/trivy",
        "rootfs",
        "--pkg-types", "os",
        "--scanners", "vuln",
        "--format", "json",
        "--quiet",
        "/",
    ]

    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=1800,
        check=False,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"Trivy failed with exit code {result.returncode}: "
            f"{result.stderr.strip()}"
        )

    return json.loads(result.stdout)


def collect_findings(report: dict) -> list[dict]:
    findings = []

    for result in report.get("Results") or []:
        for vuln in result.get("Vulnerabilities") or []:
            findings.append(
                {
                    "cve": vuln.get("VulnerabilityID", "UNKNOWN"),
                    "package": vuln.get("PkgName", "unknown"),
                    "installed": vuln.get("InstalledVersion", ""),
                    "fixed": vuln.get("FixedVersion", ""),
                    "severity": (
                        vuln.get("Severity") or "UNKNOWN"
                    ).upper(),
                }
            )

    return findings


def is_actionable_detail(finding: dict) -> bool:
    """
    A finding is actionable when:
      - severity is CRITICAL or HIGH
      - Trivy reports a known fixed version
    """
    return (
        finding["severity"] in {"CRITICAL", "HIGH"}
        and bool(finding["fixed"])
    )


def write_metrics(output_file: Path, findings: list[dict]) -> None:
    severities = Counter(
        finding["severity"]
        for finding in findings
    )

    unique_cves = {
        finding["cve"]
        for finding in findings
        if finding["cve"] != "UNKNOWN"
    }

    fixable_total = sum(
        1
        for finding in findings
        if finding["fixed"]
    )

    fixable_critical = sum(
        1
        for finding in findings
        if (
            finding["severity"] == "CRITICAL"
            and finding["fixed"]
        )
    )

    fixable_high = sum(
        1
        for finding in findings
        if (
            finding["severity"] == "HIGH"
            and finding["fixed"]
        )
    )

    unfixed_critical = sum(
        1
        for finding in findings
        if (
            finding["severity"] == "CRITICAL"
            and not finding["fixed"]
        )
    )

    unfixed_high = sum(
        1
        for finding in findings
        if (
            finding["severity"] == "HIGH"
            and not finding["fixed"]
        )
    )

    actionable_details = [
        finding
        for finding in findings
        if is_actionable_detail(finding)
    ]

    unfixed_critical_details = [
        finding
        for finding in findings
        if (
            finding["severity"] == "CRITICAL"
            and not finding["fixed"]
        )
    ]

    lines = [
        "# HELP homelab_vulnerabilities_total "
        "Current OS vulnerability/package findings reported by Trivy.",
        "# TYPE homelab_vulnerabilities_total gauge",
        f"homelab_vulnerabilities_total {len(findings)}",

        "# HELP homelab_vulnerabilities_unique_cves "
        "Number of unique CVE identifiers currently reported by Trivy.",
        "# TYPE homelab_vulnerabilities_unique_cves gauge",
        f"homelab_vulnerabilities_unique_cves {len(unique_cves)}",

        "# HELP homelab_vulnerabilities_critical "
        "Current critical OS vulnerability/package findings.",
        "# TYPE homelab_vulnerabilities_critical gauge",
        f'homelab_vulnerabilities_critical '
        f'{severities.get("CRITICAL", 0)}',

        "# HELP homelab_vulnerabilities_high "
        "Current high OS vulnerability/package findings.",
        "# TYPE homelab_vulnerabilities_high gauge",
        f'homelab_vulnerabilities_high '
        f'{severities.get("HIGH", 0)}',

        "# HELP homelab_vulnerabilities_medium "
        "Current medium OS vulnerability/package findings.",
        "# TYPE homelab_vulnerabilities_medium gauge",
        f'homelab_vulnerabilities_medium '
        f'{severities.get("MEDIUM", 0)}',

        "# HELP homelab_vulnerabilities_low "
        "Current low OS vulnerability/package findings.",
        "# TYPE homelab_vulnerabilities_low gauge",
        f'homelab_vulnerabilities_low '
        f'{severities.get("LOW", 0)}',

        "# HELP homelab_vulnerabilities_unknown "
        "Current unknown-severity OS vulnerability/package findings.",
        "# TYPE homelab_vulnerabilities_unknown gauge",
        f'homelab_vulnerabilities_unknown '
        f'{severities.get("UNKNOWN", 0)}',

        "# HELP homelab_vulnerabilities_fixable "
        "Current vulnerability/package findings with a known fixed version.",
        "# TYPE homelab_vulnerabilities_fixable gauge",
        f"homelab_vulnerabilities_fixable {fixable_total}",

        "# HELP homelab_vulnerabilities_fixable_critical "
        "Critical vulnerability/package findings with a known fixed version.",
        "# TYPE homelab_vulnerabilities_fixable_critical gauge",
        f"homelab_vulnerabilities_fixable_critical "
        f"{fixable_critical}",

        "# HELP homelab_vulnerabilities_fixable_high "
        "High vulnerability/package findings with a known fixed version.",
        "# TYPE homelab_vulnerabilities_fixable_high gauge",
        f"homelab_vulnerabilities_fixable_high "
        f"{fixable_high}",

        "# HELP homelab_vulnerabilities_unfixed_critical "
        "Critical vulnerability/package findings without a known fixed version.",
        "# TYPE homelab_vulnerabilities_unfixed_critical gauge",
        f"homelab_vulnerabilities_unfixed_critical "
        f"{unfixed_critical}",

        "# HELP homelab_vulnerabilities_unfixed_high "
        "High vulnerability/package findings without a known fixed version.",
        "# TYPE homelab_vulnerabilities_unfixed_high gauge",
        f"homelab_vulnerabilities_unfixed_high "
        f"{unfixed_high}",

        "# HELP homelab_vulnerability_actionable_details "
        "Number of CRITICAL or HIGH findings with a known fixed version.",
        "# TYPE homelab_vulnerability_actionable_details gauge",
        f"homelab_vulnerability_actionable_details "
        f"{len(actionable_details)}",

        "# HELP homelab_vulnerability_scan_timestamp_seconds "
        "Unix timestamp of the last successful vulnerability scan.",
        "# TYPE homelab_vulnerability_scan_timestamp_seconds gauge",
        f"homelab_vulnerability_scan_timestamp_seconds "
        f"{int(time.time())}",

        "# HELP homelab_vulnerability_scan_success "
        "Whether the most recent vulnerability scan succeeded.",
        "# TYPE homelab_vulnerability_scan_success gauge",
        "homelab_vulnerability_scan_success 1",

        "# HELP homelab_vulnerability_info "
        "Actionable CRITICAL or HIGH vulnerability with a known fixed version.",
        "# TYPE homelab_vulnerability_info gauge",

        "# HELP homelab_vulnerability_unfixed_info "
        "Unfixed CRITICAL vulnerability with no known fixed version.",
        "# TYPE homelab_vulnerability_unfixed_info gauge",
    ]

    for finding in sorted(
        actionable_details,
        key=lambda x: (
            x["severity"] != "CRITICAL",
            x["cve"],
            x["package"],
        ),
    ):
        labels = {
            "cve": finding["cve"],
            "package": finding["package"],
            "severity": finding["severity"],
            "installed_version": finding["installed"],
            "fixed_version": finding["fixed"],
        }

        label_text = ",".join(
            f'{key}="{prom_escape(value)}"'
            for key, value in labels.items()
        )

        lines.append(
            f"homelab_vulnerability_info"
            f"{{{label_text}}} 1"
        )

    for finding in sorted(
        unfixed_critical_details,
        key=lambda x: (
            x["cve"],
            x["package"],
        ),
    ):
        labels = {
            "cve": finding["cve"],
            "package": finding["package"],
            "severity": finding["severity"],
            "installed_version": finding["installed"],
        }

        label_text = ",".join(
            f'{key}="{prom_escape(value)}"'
            for key, value in labels.items()
        )

        lines.append(
            f"homelab_vulnerability_unfixed_info"
            f"{{{label_text}}} 1"
        )

    output_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    fd, tmp_name = tempfile.mkstemp(
        prefix=output_file.name + ".",
        dir=output_file.parent,
    )

    try:
        with os.fdopen(
            fd,
            "w",
            encoding="utf-8",
        ) as handle:
            handle.write(
                "\n".join(lines) + "\n"
            )

        os.chmod(tmp_name, 0o644)
        os.replace(
            tmp_name,
            output_file,
        )

    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def write_failure_metric(output_file: Path) -> None:
    output_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    output_file.write_text(
        "# HELP homelab_vulnerability_scan_success "
        "Whether the most recent vulnerability scan succeeded.\n"
        "# TYPE homelab_vulnerability_scan_success gauge\n"
        "homelab_vulnerability_scan_success 0\n",
        encoding="utf-8",
    )

    os.chmod(output_file, 0o644)


def main() -> int:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--output-dir",
        required=True,
        help="Node Exporter textfile collector directory",
    )

    parser.add_argument(
        "--output-name",
        default="vulnerability_status.prom",
    )

    args = parser.parse_args()

    output_file = (
        Path(args.output_dir)
        / args.output_name
    )

    try:
        report = run_trivy()
        findings = collect_findings(report)

        write_metrics(
            output_file,
            findings,
        )

        actionable = sum(
            1
            for finding in findings
            if is_actionable_detail(finding)
        )

        unique_cves = len(
            {
                finding["cve"]
                for finding in findings
                if finding["cve"] != "UNKNOWN"
            }
        )

        print(
            f"{socket.gethostname()}: "
            f"{len(findings)} vulnerability/package findings; "
            f"{unique_cves} unique CVEs; "
            f"{sum(1 for f in findings if f['severity'] == 'CRITICAL')} "
            f"critical; "
            f"{sum(1 for f in findings if f['severity'] == 'HIGH')} "
            f"high; "
            f"{actionable} actionable findings"
        )

        return 0

    except Exception as exc:
        print(
            f"Vulnerability scan failed: {exc}",
            file=sys.stderr,
        )

        write_failure_metric(
            output_file
        )

        return 1


if __name__ == "__main__":
    raise SystemExit(main())
