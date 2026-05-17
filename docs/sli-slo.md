# Anvila API SLI and SLO Definitions

## Four Golden Signals

### Latency

Successful request latency:

```promql
histogram_quantile(0.95, sum by (le, route) (rate(http_request_duration_seconds_bucket{status!~"5.."}[5m])))
```

Error request latency:

```promql
histogram_quantile(0.95, sum by (le, route) (rate(http_request_duration_seconds_bucket{status=~"5.."}[5m])))
```

SLO: 95% of successful requests complete under 500ms over a rolling 30-day window.

Reasoning: 500ms is fast enough for API consumers while still realistic for a student production deployment.

### Traffic

```promql
sum(rate(http_requests_total{service="anvila-api"}[5m]))
```

SLO: The service should handle normal traffic without saturation above the infrastructure thresholds.

Reasoning: Traffic itself is not good or bad; it explains whether latency and errors are happening under real demand.

### Errors

```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / clamp_min(sum(rate(http_requests_total[5m])), 1)
```

SLO: 99% of requests should succeed over 30 days.

Reasoning: A 1% error budget is strict enough to catch regressions but realistic while instrumentation is being introduced.

### Saturation

CPU:

```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Memory:

```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

Disk:

```promql
(1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"})) * 100
```

SLO: CPU and memory should stay below 80% during normal operation, and disk should stay below 75%.

Reasoning: These thresholds leave enough headroom to absorb spikes and avoid cascading failures.

## Availability SLO

Primary SLO:

```promql
avg_over_time(probe_success{job="blackbox-http"}[30d]) >= 0.995
```

Target: 99.5% availability over 30 days.

Error budget:

```text
(1 - 0.995) * 30 days = 0.15 days = 3.6 hours
```

That means Anvila API is allowed about 3 hours and 36 minutes of probe failure in a 30-day window.

