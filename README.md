# Kestrel Linux CPU utilization repro

This repository reproduces a case where a default ASP.NET Core Minimal API
leaves about 19-21% of a 24-CPU Linux host idle under a sustained local HTTP/1.1
plaintext load, despite 1,024 concurrent connections. Control servers on the
same host and kernel reach about 97-99% whole-host CPU utilization.

This is an investigation of Kestrel scaling/default behavior, not a claim that
Go or Java is directly comparable or that .NET 11 regressed from .NET 8.

## Build

Use a .NET 11 RC2/nightly SDK with the public `dotnet11` feed from
`NuGet.Config`:

```bash
dotnet publish src/KestrelCpuRepro/KestrelCpuRepro.csproj \
  -c Release --self-contained -r linux-x64 \
  -o artifacts/publish \
  --configfile NuGet.Config
```

## Run

```bash
ASPNETCORE_URLS=http://localhost:5000 \
DOTNET_ENVIRONMENT=Production \
./artifacts/publish/KestrelCpuRepro
```

In another terminal, find the server PID and run the included measurement
script. It performs a 20-second warm-up followed by the reported 30-second test:

```bash
scripts/benchmark.sh <server-pid> http://localhost:5000/
```

The measured load command is:

```bash
wrk --latency -t24 -c1024 -d30s http://localhost:5000/
```

Raw `wrk`, `pidstat`, and `mpstat` output from the reported runs is under
[`results/`](results/). See [the summary](results/summary.md) and
[environment details](results/environment.md).

## Screenshots

The screenshots were captured during the original manual tests of .NET 10,
.NET 11 RC2, Go Fiber, and Quarkus. The text results in `results/` were collected
separately with corrected file-descriptor limits and should be treated as the
authoritative measurements.
