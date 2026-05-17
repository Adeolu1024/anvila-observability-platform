# Blameless Post-Incident Review: Simulated Latency Incident

Date: TBD

Service: Anvila API

Owner: Anvila DevOps team

## Summary

A simulated latency injection caused requests to exceed the latency SLO and increased error budget burn. The monitoring stack detected the degradation, alerted Slack, and allowed investigation through Grafana, Loki, and Tempo.

## Timeline

| Time | Event |
| --- | --- |
| TBD | Latency injection started |
| TBD | Latency panel degraded |
| TBD | SLO burn rate alert fired |
| TBD | Logs reviewed in Loki |
| TBD | Slow trace opened in Tempo |
| TBD | Latency injection removed |
| TBD | Alert resolved |

## Impact

Staging API users experienced slow responses during the simulation window.

## Root Cause

Controlled artificial latency added during Game Day testing.

## What Went Well

- Dashboards showed the degradation quickly.
- Alertmanager routed a structured alert to Slack.
- Trace drill-down identified the slow endpoint.

## What Can Improve

- Add clearer endpoint labels to application metrics.
- Add direct deployment metadata annotations to Grafana dashboards.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Add endpoint-level OpenTelemetry spans | Anvila DevOps | TBD |
| Add GitHub deployment annotations to Grafana | Anvila DevOps | TBD |
| Confirm production app server IP target | Anvila DevOps | TBD |

