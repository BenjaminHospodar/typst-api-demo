#!/usr/bin/env python3
"""Sustained load test for sync PDF generation."""

from __future__ import annotations

import argparse
import asyncio
import os
import time
from dataclasses import dataclass, field

import httpx

from load_env import base_url, load_dotenv

INVOICE_PAYLOAD = {
    "form": "invoice",
    "version": "2.0.0",
    "fields": {
        "name": "Stress Test Corp",
        "date": "2024-04-13",
        "text1": "Load test line item",
        "text3": "Net 30",
    },
}

MINIMAL_PAYLOAD = {
    "form": "minimal",
    "version": "1.0.0",
    "fields": {"name": "Speed", "date": "2024-04-13"},
}


@dataclass
class Sample:
    status: int
    latency_ms: float
    ok: bool


@dataclass
class PhaseResult:
    name: str
    samples: list[Sample] = field(default_factory=list)

    @property
    def error_rate(self) -> float:
        if not self.samples:
            return 0.0
        return sum(1 for s in self.samples if not s.ok) / len(self.samples)

    def latency_ms(self, percentile: float) -> float:
        if not self.samples:
            return 0.0
        values = sorted(s.latency_ms for s in self.samples)
        index = min(len(values) - 1, int(len(values) * percentile))
        return values[index]


def headers(api_key: str | None) -> dict[str, str]:
    h = {"Content-Type": "application/json"}
    if api_key:
        h["X-API-Key"] = api_key
    return h


async def request_once(
    client: httpx.AsyncClient,
    endpoint: str,
    payload: dict,
    hdrs: dict[str, str],
) -> Sample:
    start = time.perf_counter()
    try:
        response = await client.post(endpoint, json=payload, headers=hdrs)
        latency_ms = (time.perf_counter() - start) * 1000
        ok = response.status_code in (200, 202)
        return Sample(response.status_code, latency_ms, ok)
    except httpx.HTTPError:
        latency_ms = (time.perf_counter() - start) * 1000
        return Sample(0, latency_ms, False)


async def run_concurrent(
    endpoint: str,
    payload: dict,
    hdrs: dict[str, str],
    workers: int,
    duration_s: float,
    pause_s: float,
) -> list[Sample]:
    samples: list[Sample] = []
    lock = asyncio.Lock()
    stop_at = time.monotonic() + duration_s

    async with httpx.AsyncClient(timeout=30.0) as client:
        async def worker() -> None:
            while time.monotonic() < stop_at:
                sample = await request_once(client, endpoint, payload, hdrs)
                async with lock:
                    samples.append(sample)
                if pause_s:
                    await asyncio.sleep(pause_s)

        await asyncio.gather(*(worker() for _ in range(workers)))

    return samples


async def run_arrival_rate(
    endpoint: str,
    payload: dict,
    hdrs: dict[str, str],
    rate_per_s: float,
    duration_s: float,
) -> list[Sample]:
    samples: list[Sample] = []
    interval = 1.0 / rate_per_s
    stop_at = time.monotonic() + duration_s

    async with httpx.AsyncClient(timeout=30.0) as client:
        while time.monotonic() < stop_at:
            started = time.monotonic()
            sample = await request_once(client, endpoint, payload, hdrs)
            samples.append(sample)
            elapsed = time.monotonic() - started
            sleep_for = interval - elapsed
            if sleep_for > 0:
                await asyncio.sleep(sleep_for)

    return samples


def print_phase(result: PhaseResult) -> None:
    print(f"\n=== {result.name} ===")
    print(f"Requests:   {len(result.samples)}")
    print(f"Error rate: {result.error_rate * 100:.2f}%")
    if result.samples:
        latencies = [s.latency_ms for s in result.samples]
        print(f"Latency ms: min={min(latencies):.0f} p50={result.latency_ms(0.50):.0f} "
              f"p95={result.latency_ms(0.95):.0f} max={max(latencies):.0f}")


async def run_suite(base_url: str, api_key: str | None, quick: bool) -> int:
    endpoint = f"{base_url.rstrip('/')}/api/v1/generate"
    hdrs = headers(api_key)

    warmup_s = 5.0 if quick else 30.0
    sustained_s = 10.0 if quick else 120.0
    minimal_s = 5.0 if quick else 60.0

    phases = [
        PhaseResult(
            "warmup",
            await run_concurrent(endpoint, INVOICE_PAYLOAD, hdrs, workers=2, duration_s=warmup_s, pause_s=0.1),
        ),
        PhaseResult(
            "sustained",
            await run_arrival_rate(endpoint, INVOICE_PAYLOAD, hdrs, rate_per_s=10.0, duration_s=sustained_s),
        ),
        PhaseResult(
            "minimal_fast",
            await run_concurrent(endpoint, MINIMAL_PAYLOAD, hdrs, workers=5, duration_s=minimal_s, pause_s=0.0),
        ),
    ]

    print("=== PDF Generation — Sync Load Test ===")
    print(f"Target: {endpoint}")
    for phase in phases:
        print_phase(phase)

    worst_p95 = max((p.latency_ms(0.95) for p in phases if p.samples), default=0.0)
    worst_error = max((p.error_rate for p in phases), default=0.0)

    print("\n=== Thresholds ===")
    if worst_error < 0.05:
        print(f"PASS: error rate {worst_error * 100:.2f}% < 5%")
    else:
        print(f"FAIL: error rate {worst_error * 100:.2f}% >= 5%")

    if worst_p95 < 5000:
        print(f"PASS: p95 latency {worst_p95:.0f} ms < 5000 ms")
    else:
        print(f"FAIL: p95 latency {worst_p95:.0f} ms >= 5000 ms")

    return 0 if worst_error < 0.05 and worst_p95 < 5000 else 1


def main() -> int:
    load_dotenv()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default=base_url())
    parser.add_argument(
        "--api-key",
        default=os.environ.get("API_KEY") or os.environ.get("PDFGEN_API_KEY"),
    )
    parser.add_argument("--quick", action="store_true", help="Shorter durations for local smoke runs")
    args = parser.parse_args()
    return asyncio.run(run_suite(args.base_url, args.api_key, args.quick))


if __name__ == "__main__":
    raise SystemExit(main())
