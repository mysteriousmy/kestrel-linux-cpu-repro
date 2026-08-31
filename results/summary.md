# Benchmark summary

All tests used the same physical host, kernel, desktop session, `wrk 4.2.0`, and:

```text
wrk --latency -t24 -c1024 -d30s http://localhost:<port>/
```

The load-generator shell soft `nofile` limit was raised to its hard limit of
1,048,576 before every recorded run. The server and `wrk` processes both ran
with the same `SCHED_OTHER` policy and nice value (`-4`, assigned by the host's
desktop scheduling policy).

## ASP.NET Core 11 RC2, original app, three recorded runs

Runtime: `Microsoft.AspNetCore.App 11.0.0-rc.2.26429.118`

| Run | Requests/sec | Avg latency | p50 | p90 | p99 | Kestrel CPU | wrk CPU | Whole-host busy | Whole-host idle |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1,896,732.88 | 536.58 us | 437 us | 0.96 ms | 1.92 ms | 1,067.23% | 396.13% | 80.44% | 19.56% |
| 2 | 1,896,001.27 | 534.36 us | 441 us | 0.95 ms | 1.89 ms | 1,052.60% | 396.87% | 80.25% | 19.75% |
| 3 | 1,851,142.27 | 547.52 us | 450 us | 0.97 ms | 1.92 ms | 1,045.05% | 386.34% | 79.48% | 20.52% |
| Median | **1,896,001.27** | **536.58 us** | **441 us** | **0.96 ms** | **1.92 ms** | **1,052.60%** | **396.13%** | **80.25%** | **19.75%** |

`pidstat` CPU percentages use 100% per logical CPU, so the median Kestrel CPU
value corresponds to about 10.5 of the host's 24 CPUs.

## Reduced minimal repro

The repository's two-line endpoint (no HTTPS redirection, no weather endpoint)
still reproduced the behavior:

| Runtime | Requests/sec | Kestrel CPU | wrk CPU | Whole-host busy | Whole-host idle |
|---|---:|---:|---:|---:|---:|
| .NET 11 RC2 minimal repro | 1,849,015.25 | 1,095.17% | 386.33% | 81.02% | 18.98% |

## Same-host .NET 8 baseline

The same source was rebuilt with the latest .NET 8 servicing SDK/runtime to
check the remembered historical behavior on the current hardware and kernel.
It also reproduced the idle CPU, so the collected evidence does **not** establish
a .NET 10/11 regression:

| Runtime | Requests/sec | Kestrel CPU | wrk CPU | Whole-host busy | Whole-host idle |
|---|---:|---:|---:|---:|---:|
| ASP.NET Core 8.0.30 / SDK 8.0.424 | 1,844,115.41 | 1,037.23% | 381.17% | 78.16% | 21.84% |

## Control servers

These are controls showing that the same kernel, load generator, connection
count, and host can reach near-full CPU utilization. They are **not** intended
as framework rankings: response bodies, response headers, transfer encoding,
and server implementations differ.

| Server | Requests/sec | Server CPU | wrk CPU | Whole-host busy | Whole-host idle |
|---|---:|---:|---:|---:|---:|
| Go 1.26.5 / Fiber 3.4.0 | 3,336,250.77 | 951.55% | 688.37% | 97.23% | 2.77% |
| OpenJDK 25.0.4.1 / Quarkus 3.38.2 | 1,950,880.99 | 1,637.21% | 377.38% | 98.61% | 1.39% |

## Configuration probes

Two isolated ASP.NET Core 11 processes were tested without modifying the
default-process result above:

| Change | Requests/sec | Kestrel CPU | Whole-host idle | Observation |
|---|---:|---:|---:|---|
| `SocketTransportOptions.IOQueueCount = 24` | 1,830,795.65 | 1,055.28% | 20.89% | Did not improve utilization or throughput |
| `DOTNET_SYSTEM_NET_SOCKETS_THREAD_COUNT=2` | 1,897,544.03 | 1,153.47% | 16.60% | Consumed more CPU without improving throughput |

An `oha 1.15.0` cross-check (`-c 1024 -z 30s --ipv4`) also left 20.23%
whole-host CPU idle while reporting a 100% HTTP success rate.
