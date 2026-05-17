# Runbook: HighCPUWarning / HighCPUCritical

## What This Alert Means

CPU usage crossed 80% for warning or 90% for critical.

## Likely Causes

- Traffic spike.
- Expensive application code path.
- Runaway process.
- Background job consuming CPU.

## First 3 Investigation Steps

1. Open the Node Exporter dashboard and check CPU trend.
2. SSH into the affected host and run `top` or `htop`.
3. Check recent deployments and application logs for new errors.

## Resolution

Stop or restart the runaway process, scale the service, or rollback a deployment that introduced the CPU spike.

## Rollback Guidance

Rollback if the spike began after a deployment and the new version owns the hot process.

## Escalation

Escalate to the Anvila DevOps team if CPU remains critical for more than 15 minutes.

