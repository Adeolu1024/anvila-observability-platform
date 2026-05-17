# Runbook: ChangeFailureRateHigh

## What This Alert Means

Too many recent deployments are failing, rolling back, or requiring hotfixes.

## Likely Causes

- Weak pre-deployment checks.
- Broken staging validation.
- Manual deployment steps.
- Unstable migrations or environment variables.

## First 3 Investigation Steps

1. Open the DORA dashboard and confirm the failing deployment window.
2. Open GitHub Actions and inspect failed runs for `Deploy Staging` or `Deploy Production`.
3. Compare failures against recent commits and environment changes.

## Resolution

Fix the deployment workflow, add preflight checks, or rollback the failing release.

## Rollback Guidance

Rollback production if the deployment caused user-facing errors or outage.

## Escalation

Escalate to Anvila DevOps if CFR remains above 15% after two deployment attempts.

