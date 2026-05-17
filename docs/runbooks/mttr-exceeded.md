# Runbook: MTTRExceeded

## What This Alert Means

The mean time to restore service has exceeded the 60-minute target.

## Likely Causes

- Incident ownership unclear.
- Runbook missing or incomplete.
- Recovery requires manual access.
- Rollback process is slow.

## First 3 Investigation Steps

1. Review active alerts in Alertmanager.
2. Identify the incident start time and current owner.
3. Check whether rollback or mitigation has been attempted.

## Resolution

Assign a single incident lead, execute the relevant service runbook, and choose rollback if recovery is blocked.

## Rollback Guidance

Rollback when the current version is suspected and no fix is available within the target recovery window.

## Escalation

Escalate to the Anvila DevOps team lead immediately when MTTR exceeds target.

