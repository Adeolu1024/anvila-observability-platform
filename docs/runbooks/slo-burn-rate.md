# Runbook: SLOFastBurn / SLOSlowBurn

## What This Alert Means

The service is consuming its availability error budget too quickly.

## Likely Causes

- Application outage.
- Increased 5xx errors.
- Severe latency causing probes to fail.
- Network or DNS issue.

## First 3 Investigation Steps

1. Open the SLO & Error Budget dashboard and identify the affected window.
2. Open the Unified Observability dashboard and compare error, latency, logs, and traces.
3. Check recent deployments in GitHub Actions.

## Resolution

Fix the failing service, rollback a bad deployment, or mitigate the dependency/network issue.

## Rollback Guidance

Rollback immediately for fast burn if a recent deployment is the likely trigger.

## Escalation

Escalate to the Anvila DevOps team immediately for critical fast-burn alerts.

