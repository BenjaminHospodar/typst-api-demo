#!/usr/bin/env python3
"""Load test for API error paths (404/400)."""

from __future__ import annotations

import argparse
import asyncio
import time
from dataclasses import dataclass

import httpx

from load_env import base_url, load_dotenv


@dataclass
class Counters:
    checks: int = 0
    failures: int = 0


async def check_status(
    client: httpx.AsyncClient,
    endpoint: str,
    payload: dict,
    expected: int,
    counters: Counters,
) -> None:
    try:
        response = await client.post(endpoint, json=payload)
        ok = response.status_code == expected
    except httpx.HTTPError:
        ok = False

    counters.checks += 1
    if not ok:
        counters.failures += 1


async def worker(endpoint: str, duration_s: float, counters: Counters) -> None:
    stop_at = time.monotonic() + duration_s
    async with httpx.AsyncClient(timeout=10.0) as client:
        while time.monotonic() < stop_at:
            await check_status(
                client,
                endpoint,
                {"form": "nonexistent", "version": "1.0.0", "fields": {"name": "X"}},
                404,
                counters,
            )
            await check_status(
                client,
                endpoint,
                {"form": "", "version": ""},
                400,
                counters,
            )
            await asyncio.sleep(0.5)


async def run_suite(base_url: str, workers: int, duration_s: float) -> int:
    endpoint = f"{base_url.rstrip('/')}/api/v1/generate"
    counters = Counters()

    print("=== PDF Generation — Error Path Load Test ===")
    print(f"Target: {endpoint}")
    print(f"Workers: {workers}, duration: {duration_s:.0f}s")

    await asyncio.gather(*(worker(endpoint, duration_s, counters) for _ in range(workers)))

    failure_rate = counters.failures / counters.checks if counters.checks else 1.0
    print(f"\nChecks: {counters.checks}")
    print(f"Failures: {counters.failures}")
    print(f"Failure rate: {failure_rate * 100:.2f}%")

    if failure_rate < 0.10:
        print("PASS: failure rate < 10%")
        return 0

    print("FAIL: failure rate >= 10%")
    return 1


def main() -> int:
    load_dotenv()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default=base_url())
    parser.add_argument("--workers", type=int, default=5)
    parser.add_argument("--duration", type=float, default=60.0, help="Duration in seconds")
    parser.add_argument("--quick", action="store_true", help="Run for 10 seconds")
    args = parser.parse_args()

    duration = 10.0 if args.quick else args.duration
    return asyncio.run(run_suite(args.base_url, args.workers, duration))


if __name__ == "__main__":
    raise SystemExit(main())
