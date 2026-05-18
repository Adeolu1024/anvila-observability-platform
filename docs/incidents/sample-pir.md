# Blameless Post-Incident Review: Simulated Latency Incident

Date: 2026-05-18

Service: Anvila API

Owner: Anvila DevOps team

## Summary

A simulated latency injection caused requests to exceed the latency SLO and increased error budget burn. The monitoring stack detected the degradation, alerted Slack, and allowed investigation through Grafana, Loki, and Tempo.

## Timeline

| Time | Event |
| --- | --- |
| 16:40 WAT | Latency injection approved for staging only |
| 16:43 WAT | Temporary `time.sleep(2)` added to the staging root endpoint |
| 16:44 WAT | Local staging request latency confirmed at about 2 seconds |
| 16:45 WAT | Delayed requests generated against `http://localhost:8000/` |
| 16:46 WAT | Tempo traces reviewed for `anvila-api-staging` and `GET /` |
| 16:48 WAT | Latency injection removed and `backend-staging` restarted |
| 16:49 WAT | Recovery confirmed with local response time below 10ms |

## Impact

Staging API users experienced slow responses during the simulation window.

## Root Cause

Controlled artificial latency added during Game Day testing.

## What Went Well

- Tempo captured request traces for the affected staging endpoint.
- The rollback path was simple because the original file was backed up before modification.
- The staging-only test avoided production impact.

## What Can Improve

- Add first-class Prometheus HTTP metrics from the FastAPI app.
- Keep OpenTelemetry instrumentation managed by deployment code so it does not drift after restarts.
- Add direct deployment metadata annotations to Grafana dashboards.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Add endpoint-level Prometheus metrics | Anvila DevOps | 2026-05-25 |
| Add GitHub deployment annotations to Grafana | Anvila DevOps | 2026-05-25 |
| Confirm production app server IP target | Anvila DevOps | Done on 2026-05-18 |
