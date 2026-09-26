"""Mide latencia HTTP reproducible contra una instancia local o desplegada."""

import argparse
import statistics
import sys
import time

import httpx


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    index = min(len(ordered) - 1, round((len(ordered) - 1) * fraction))
    return ordered[index]


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark RNF de FestiSquad")
    parser.add_argument("--url", default="http://127.0.0.1:8000/health")
    parser.add_argument("--requests", type=int, default=30)
    parser.add_argument("--target-ms", type=float, default=1500)
    args = parser.parse_args()
    if args.requests < 1:
        parser.error("--requests debe ser mayor que cero")

    samples: list[float] = []
    with httpx.Client(timeout=5.0) as client:
        client.get(args.url).raise_for_status()
        for _ in range(args.requests):
            started = time.perf_counter()
            response = client.get(args.url)
            elapsed_ms = (time.perf_counter() - started) * 1000
            response.raise_for_status()
            samples.append(elapsed_ms)

    p95 = percentile(samples, 0.95)
    print(f"URL: {args.url}")
    print(f"Muestras: {len(samples)}")
    print(f"Promedio: {statistics.fmean(samples):.2f} ms")
    print(f"P95: {p95:.2f} ms")
    print(f"Máximo: {max(samples):.2f} ms")
    print(f"Objetivo: < {args.target_ms:.0f} ms ({'CUMPLE' if p95 < args.target_ms else 'NO CUMPLE'})")
    return 0 if p95 < args.target_ms else 1


if __name__ == "__main__":
    sys.exit(main())
