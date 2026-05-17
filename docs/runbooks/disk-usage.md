# Runbook: DiskUsageWarning / DiskUsageCritical

## What This Alert Means

Disk usage crossed 75% for warning or 90% for critical.

## Likely Causes

- Large log files.
- Build artifacts or uploads filling the disk.
- Retention policy not working.
- Database or cache growth.

## First 3 Investigation Steps

1. Open the Node Exporter dashboard and identify the filesystem.
2. SSH into the host and run `df -h`.
3. Run `du -h --max-depth=1 /var /opt /home 2>/dev/null | sort -h`.

## Resolution

Rotate or delete safe old logs, remove temporary artifacts, increase disk size, or fix retention.

## Rollback Guidance

Rollback if a deployment started writing unexpectedly large files.

## Escalation

Escalate to the Anvila DevOps team before deleting unknown files.

