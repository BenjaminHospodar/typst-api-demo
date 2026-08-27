#!/usr/bin/env python3
"""Functional smoke tests for the PDF generation pipeline."""

from __future__ import annotations

import argparse
import sys
import os
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parent))
from load_env import base_url, load_dotenv

GREEN = "\033[32m"
RED = "\033[31m"
BOLD = "\033[1m"
RESET = "\033[0m"


def bold(msg: str) -> None:
    print(f"{BOLD}{msg}{RESET}")


def green(msg: str) -> None:
    print(f"{GREEN}{msg}{RESET}")


def red(msg: str) -> None:
    print(f"{RED}{msg}{RESET}")


class Runner:
    def __init__(self, base_url: str, timeout: float, api_key: str | None) -> None:
        self.base_url = base_url.rstrip("/")
        headers = {}
        if api_key:
            headers["X-API-Key"] = api_key
        self.client = httpx.Client(timeout=timeout, headers=headers)
        self.passed = 0
        self.failed = 0
        self.failures: list[str] = []

    def close(self) -> None:
        self.client.close()

    def check(
        self,
        name: str,
        method: str,
        path: str,
        *,
        json_body: dict | None = None,
        expected: tuple[int, ...] = (200,),
    ) -> httpx.Response | None:
        url = f"{self.base_url}{path}"
        response = self.client.request(method, url, json=json_body)

        if response.status_code in expected:
            green(f"  PASS: {name} (HTTP {response.status_code})")
            self.passed += 1
            return response

        expected_str = "|".join(str(code) for code in expected)
        red(f"  FAIL: {name} (expected {expected_str}, got {response.status_code})")
        self.failed += 1
        self.failures.append(name)
        return None

    def run(self) -> int:
        bold("=== PDF Generation Pipeline — Functional Tests ===")
        print()

        bold("1. Health check")
        self.check("GET /actuator/health", "GET", "/actuator/health")

        bold("2. Generate invoice v2.0.0 (sync)")
        response = self.check(
            "Generate invoice v2.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "invoice",
                "version": "2.0.0",
                "fields": {
                    "name": "Acme Corp",
                    "date": "2024-04-13",
                    "text1": "Consulting services",
                },
            },
            expected=(200, 202),
        )
        if response is not None and response.status_code == 200:
            if response.content[:4] == b"%PDF":
                green(f"  PASS: Invoice PDF generated ({len(response.content)} bytes)")
                self.passed += 1
            else:
                red("  FAIL: Response is not a valid PDF")
                self.failed += 1
                self.failures.append("Invoice PDF validation")

        bold("3. Generate invoice v2.0.0")
        self.check(
            "Invoice v2.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "invoice",
                "version": "2.0.0",
                "fields": {"name": "Test Corp", "date": "2024-01-01", "text1": "Hello"},
            },
            expected=(200, 202),
        )

        bold("4. Generate report v2.0.0 (tables + columns)")
        self.check(
            "Report v2.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "report",
                "version": "2.0.0",
                "fields": {
                    "name": "GlobalTech Inc",
                    "date": "2024-12-31",
                    "text1": "Outstanding year with record revenue.",
                    "text3": "Projected growth of 25% next fiscal year.",
                },
            },
            expected=(200, 202),
        )

        bold("5. Generate contract v1.0.0 (multi-page)")
        self.check(
            "Contract v1.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "contract",
                "version": "1.0.0",
                "fields": {
                    "name": "MegaCorp LLC",
                    "date": "2024-06-15",
                    "text1": "Full-stack development services for Project Phoenix.",
                },
            },
            expected=(200, 202),
        )

        bold("6. Generate dashboard v1.0.0 (KPI cards + tables)")
        self.check(
            "Dashboard v1.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "dashboard",
                "version": "1.0.0",
                "fields": {
                    "name": "SaaS Metrics Co",
                    "date": "2024-04-13",
                    "text1": "Record month for user signups.",
                    "text3": "Next board meeting in 2 weeks.",
                },
            },
            expected=(200, 202),
        )

        bold("7. Generate legal v1.0.0 (multi-page legal doc)")
        self.check(
            "Legal v1.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "legal",
                "version": "1.0.0",
                "fields": {
                    "name": "Morrison Partners LLP",
                    "date": "2026-04-13",
                    "text1": "Risk Assessment Memo",
                    "text2": "State of Delaware",
                    "text3": "Apex Holdings",
                    "text4": "Zenith Capital",
                    "text5": "CASE-2026-001",
                    "text6": "Comprehensive legal analysis of the proposed transaction.",
                    "text7": "Risk landscape dominated by regulatory uncertainty.",
                    "text8": "Maximum exposure estimated at USD 5.45 million.",
                    "text9": "HSR filing and CFIUS notice required.",
                    "text10": "All regulatory approvals and due diligence completion.",
                    "text11": "Quarterly covenant testing and key personnel retention.",
                    "text12": "Environmental remediation subject to separate indemnification.",
                },
            },
            expected=(200, 202),
        )

        bold("8. Missing template (expect 404)")
        self.check(
            "Missing template returns 404",
            "POST",
            "/api/v1/generate",
            json_body={"form": "nonexistent", "version": "1.0.0", "fields": {"name": "X"}},
            expected=(404,),
        )

        bold("9. Invalid request (missing required fields)")
        self.check(
            "Invalid request returns 400",
            "POST",
            "/api/v1/generate",
            json_body={"form": "", "version": ""},
            expected=(400,),
        )

        bold("10. Minimal template (fast path)")
        self.check(
            "Minimal v1.0.0",
            "POST",
            "/api/v1/generate",
            json_body={
                "form": "minimal",
                "version": "1.0.0",
                "fields": {"name": "Speed Test", "date": "2024-04-13"},
            },
            expected=(200, 202),
        )

        bold("11. Poll with invalid job_id (expect 404)")
        self.check(
            "Invalid job poll returns 404",
            "GET",
            "/api/v1/jobs/FAKEID/result",
            expected=(404,),
        )

        print()
        bold("=== Results ===")
        green(f"Passed: {self.passed}")
        if self.failed:
            red(f"Failed: {self.failed}")
            red("Failures:")
            for name in self.failures:
                red(f"  - {name}")
            return 1

        green("All tests passed!")
        return 0


def main() -> int:
    load_dotenv()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "base_url",
        nargs="?",
        default=base_url(),
        help="API base URL (default: BASE_URL from .env, or http://localhost:8080)",
    )
    parser.add_argument("--timeout", type=float, default=30.0, help="HTTP timeout in seconds")
    parser.add_argument(
        "--api-key",
        default=os.environ.get("PDFGEN_API_KEY") or None,
        help="X-API-Key header (default: PDFGEN_API_KEY from .env)",
    )
    args = parser.parse_args()

    runner = Runner(args.base_url, args.timeout, args.api_key or None)
    try:
        return runner.run()
    finally:
        runner.close()


if __name__ == "__main__":
    raise SystemExit(main())
