# Environment

## Host

```text
OS: CachyOS (Arch Linux family, rolling)
Kernel: Linux 7.2.0-1-cachyos, x86_64, SMP PREEMPT_DYNAMIC
glibc: 2.44
CPU: Intel Core Ultra 7 270K Plus
Topology: 1 socket, 24 physical/logical CPUs, 1 thread per core, 1 NUMA node
CPU layout: CPUs 0-7 max 5.5 GHz; CPUs 8-23 max 5.0 GHz
Memory: 46 GiB
CPU affinity: 0-23 for every tested process
CPU isolation/nohz_full: none
CPU frequency driver/governor: intel_pstate active / powersave
Kernel command line: quiet nowatchdog splash rw root=<redacted> initrd=<redacted>
net.core.somaxconn: 4096
net.ipv4.ip_local_port_range: 32768 60999
net.ipv4.tcp_tw_reuse: 2
```

The controls saturated this same host, and the observed frequencies reached the
advertised boost range, so the `powersave` HWP governor alone does not explain
the Kestrel-only idle time.

## .NET 11 tested

```text
.NET SDK: 11.0.100-rc.2.26429.118
SDK commit: afc1505248
MSBuild: 18.12.0-1.26429.118+afc150524
Host/runtime: 11.0.0-rc.2.26429.118
Microsoft.AspNetCore.App: 11.0.0-rc.2.26429.118
Architecture/RID: x64 / linux-x64
Server GC: enabled
```

## Other versions

```text
System .NET SDK: 10.0.302 (runtime and ASP.NET Core 10.0.10)
.NET 8 controlled baseline: SDK 8.0.424, runtime and ASP.NET Core 8.0.30
wrk: 4.2.0
oha: 1.15.0
sysstat: 12.7.9
Go control: go1.26.5-X:nodwarf5, Fiber 3.4.0
Java control: OpenJDK 25.0.4.1, Quarkus 3.38.2
```
