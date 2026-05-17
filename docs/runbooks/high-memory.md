# Runbook: HighMemoryWarning / HighMemoryCritical

## What This Alert Means

Memory usage crossed 80% for warning or 90% for critical.

## Likely Causes

- Memory leak.
- Traffic spike.
- Too many worker processes.
- Large query or file-processing workload.

## First 3 Investigation Steps

1. Open the Node Exporter dashboard and check memory trend.
2. SSH into the affected host and run `free -h` and `ps aux --sort=-%mem`.
3. Check application logs for worker crashes or out-of-memory messages.

## Resolution

Restart the leaking process, reduce workers, or rollback the deployment that introduced the memory growth.

## Rollback Guidance

Rollback if memory growth starts after a deployment and continues after restart.

## Escalation

Escalate to the Anvila DevOps team if memory stays critical for more than 15 minutes.

