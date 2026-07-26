#!/usr/bin/env python3
"""
Load test: measures TPS for the PDF generation pipeline
Usage: python test-load.py [--concurrency 20] [--total 500] [--base-url http://nas.benjaminhospodar.com:8080]
"""

import argparse
import asyncio
import time
from typing import List, Dict
import aiohttp
import statistics


TEMPLATES = [
    '{"form": "legal","version": "1.0.0","fields": {"name": "Morrison Partners LLP","date": "2026-04-13","text1": "Acquisition Risk Assessment","text2": "State of Delaware","text3": "Apex Holdings Inc","text4": "Zenith Capital LLC","text5": "CASE-2026-0042","text6": "Comprehensive legal analysis of the proposed transaction.","text7": "Risk landscape dominated by regulatory uncertainty.","text8": "Maximum exposure estimated at USD 5.45 million.","text9": "HSR filing and CFIUS notice required.","text10": "All regulatory approvals required.","text11": "Quarterly covenant testing and key personnel retention.","text12": "Environmental remediation subject to separate indemnification."}}'
]


class Result:
    def __init__(self, status: int, latency_ms: float):
        self.status = status
        self.latency_ms = latency_ms


async def make_request(session: aiohttp.ClientSession, endpoint: str, body: str) -> Result:
    """Make a single HTTP POST request and measure latency."""
    start = time.perf_counter()
    
    try:
        async with session.post(
            endpoint,
            data=body,
            headers={'Content-Type': 'application/json'},
            timeout=aiohttp.ClientTimeout(total=10)
        ) as response:
            await response.read()  # Consume response body
            latency_ms = (time.perf_counter() - start) * 1000
            return Result(status=response.status, latency_ms=latency_ms)
    
    except asyncio.TimeoutError:
        latency_ms = (time.perf_counter() - start) * 1000
        return Result(status=0, latency_ms=latency_ms)
    
    except aiohttp.ClientError as e:
        latency_ms = (time.perf_counter() - start) * 1000
        # Try to extract status code from error
        status = getattr(e, 'status', 0)
        return Result(status=status, latency_ms=latency_ms)
    
    except Exception:
        latency_ms = (time.perf_counter() - start) * 1000
        return Result(status=0, latency_ms=latency_ms)


async def worker(
    worker_id: int,
    request_count: int,
    endpoint: str,
    session: aiohttp.ClientSession
) -> List[Result]:
    """Worker coroutine that sends multiple requests."""
    results = []
    
    for i in range(request_count):
        # Round-robin through templates
        template_idx = (worker_id * request_count + i) % len(TEMPLATES)
        body = TEMPLATES[template_idx]
        
        result = await make_request(session, endpoint, body)
        results.append(result)
    
    return results


async def run_load_test(concurrency: int, total: int, endpoint: str) -> List[Result]:
    """Run the load test with specified concurrency."""
    # Calculate requests per worker
    per_worker = total // concurrency
    remainder = total % concurrency
    
    print(f"\n{'='*40}")
    print("PDF Generation - Load Test")
    print(f"{'='*40}")
    print(f"Concurrency:     {concurrency}")
    print(f"Total requests:  {total}")
    print(f"Target:          {endpoint}")
    print()
    
    # Create shared session with connection pooling
    connector = aiohttp.TCPConnector(
        limit=concurrency,  # Connection pool size
        limit_per_host=concurrency,
        ttl_dns_cache=300
    )
    
    async with aiohttp.ClientSession(connector=connector) as session:
        print(f"Starting {concurrency} workers...")
        overall_start = time.perf_counter()
        
        # Create worker tasks
        tasks = []
        for worker_id in range(concurrency):
            # Distribute remainder across first N workers
            count = per_worker + (1 if worker_id < remainder else 0)
            task = worker(worker_id, count, endpoint, session)
            tasks.append(task)
        
        # Run all workers concurrently
        worker_results = await asyncio.gather(*tasks)
        
        overall_duration_ms = (time.perf_counter() - overall_start) * 1000
        
        # Flatten results
        all_results = [result for results in worker_results for result in results]
        
        return all_results, overall_duration_ms


def calculate_percentile(sorted_values: List[float], percentile: float) -> float:
    """Calculate percentile from sorted list."""
    if not sorted_values:
        return 0.0
    
    index = int(len(sorted_values) * percentile)
    if index >= len(sorted_values):
        index = len(sorted_values) - 1
    
    return sorted_values[index]


def print_results(results: List[Result], duration_ms: float, total: int):
    """Print aggregated test results."""
    success_200 = sum(1 for r in results if r.status == 200)
    success_202 = sum(1 for r in results if r.status == 202)
    errors = sum(1 for r in results if r.status not in (200, 202))
    total_success = success_200 + success_202
    
    # Calculate latency statistics
    latencies = sorted([r.latency_ms for r in results])
    
    if latencies:
        p50 = calculate_percentile(latencies, 0.50)
        p95 = calculate_percentile(latencies, 0.95)
        p99 = calculate_percentile(latencies, 0.99)
        min_lat = latencies[0]
        max_lat = latencies[-1]
        avg_lat = statistics.mean(latencies)
    else:
        p50 = p95 = p99 = min_lat = max_lat = avg_lat = 0
    
    # Calculate throughput (requests per second)
    tps = (total * 1000 / duration_ms) if duration_ms > 0 else 0
    
    print()
    print(f"{'='*40}")
    print("Results")
    print(f"{'='*40}")
    print(f"Total requests:  {total}")
    print(f"Duration:        {duration_ms:.0f} ms")
    print()
    
    # Color output for throughput
    if tps >= 100:
        print(f"\033[92mThroughput:      {tps:.1f} req/s\033[0m")
    else:
        print(f"\033[91mThroughput:      {tps:.1f} req/s\033[0m")
    
    print()
    print(f"Success (200):   {success_200}")
    print(f"Async (202):     {success_202}")
    print(f"Errors:          {errors}")
    print()
    print("Latency:")
    print(f"  Min:    {min_lat:.1f} ms")
    print(f"  Avg:    {avg_lat:.1f} ms")
    print(f"  P50:    {p50:.1f} ms")
    print(f"  P95:    {p95:.1f} ms")
    print(f"  P99:    {p99:.1f} ms")
    print(f"  Max:    {max_lat:.1f} ms")
    print()
    
    # Pass/fail determination
    if tps >= 100:
        print(f"\033[92mPASS: {tps:.1f} TPS >= 100 TPS target\033[0m")
    else:
        print(f"\033[91mFAIL: {tps:.1f} TPS < 100 TPS target\033[0m")
    
    if errors > 0:
        print(f"\033[93mWARNING: {errors} errors during test\033[0m")
    
    print()


def main():
    parser = argparse.ArgumentParser(
        description='Load test for PDF generation pipeline'
    )
    parser.add_argument(
        '--concurrency', '-c',
        type=int,
        default=20,
        help='Number of concurrent workers (default: 20)'
    )
    parser.add_argument(
        '--total', '-t',
        type=int,
        default=500,
        help='Total number of requests (default: 500)'
    )
    parser.add_argument(
        '--base-url', '-u',
        type=str,
        default='http://localhost:8080',
        help='Base URL of the service (default: http://localhost:8080)'
    )
    
    args = parser.parse_args()
    
    endpoint = f"{args.base_url}/api/v1/generate"
    
    # Run the async load test
    results, duration_ms = asyncio.run(
        run_load_test(args.concurrency, args.total, endpoint)
    )
    
    # Print results
    print_results(results, duration_ms, args.total)


if __name__ == '__main__':
    main()