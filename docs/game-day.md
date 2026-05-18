# Game Day Results

Date: 2026-05-18

Environment used:

- Staging API: `https://api.staging.anvila.hng14.com`
- App server: `13.60.76.205`
- Monitoring server: `34.204.43.206`
- Production was not modified during Game Day.

## Scenario 1: Deployment Failure

Goal: Trigger a failing GitHub Actions check safely without modifying the live staging runtime.

Steps:

1. Created branch `stage6-deployment-failure-simulation` from `origin/staging`.
2. Added temporary workflow `.github/workflows/stage6-failure-simulation.yml`.
3. Opened PR `#29` into `staging`.
4. Confirmed `Stage 6 Deployment Failure Simulation / fail-for-game-day` failed after 2 seconds.
5. Confirmed normal checks still passed, proving the failure was isolated to the intentional Game Day workflow.
6. Closed the PR without merging.
7. Deleted the temporary remote branch and removed the local branch.

Result:

- The deployment/pipeline failure scenario was proven through a failing protected-branch PR check.
- Staging and production runtime were not changed.

Evidence:

- `gameday-01-deployment-success-control.png`
- `gameday-01-deployment-failure-pr.png`
- `gameday-01-deployment-failure-check.png`

## Scenario 2: Latency Injection

Goal: Simulate high latency and confirm SLI degradation, burn rate alerting, logs, and trace drill-down.

Steps:

1. Backed up `/home/agentforge/anvila/backend/staging/app/main.py`.
2. Added temporary `time.sleep(2)` to the staging root endpoint only.
3. Restarted `backend-staging` with PM2.
4. Confirmed local staging latency increased to about 2 seconds using `curl`.
5. Generated several delayed requests against `http://localhost:8000/`.
6. Confirmed Tempo received traces for `anvila-api-staging` with root span `GET /`.
7. Restored the original `app/main.py` from backup.
8. Restarted `backend-staging` and confirmed latency returned to normal.

Result:

- Staging-only latency injection worked and was reverted.
- Tempo captured traces for the Anvila staging API.
- Final local recovery check returned `time_total=0.000180`.

Evidence:

- `gameday-02-latency-injection-trigger.png`
- `gameday-02-latency-tempo-traces.png`
- `gameday-02-latency-recovery.png`

## Scenario 3: Resource Pressure

Goal: Simulate CPU or memory pressure and confirm warning, critical, and recovery alerts.

Steps:

1. Started four `yes > /dev/null` processes on the monitoring server.
2. Confirmed `HighCPUWarning` fired in Slack with current value `100`.
3. Also observed `HighMemoryWarning` while the monitoring server was under load.
4. Stopped the CPU pressure using `pkill yes`.
5. Confirmed the `HighCPUWarning` resolved notification arrived in Slack.

Result:

- Infrastructure warning alerting and recovery routing to Slack worked.
- The alert payload included alert name, severity, service, affected target, and current value.

Evidence:

- `gameday-03-resource-pressure-trigger.png`
- `gameday-03-resource-pressure-slack-firing.png`
- `gameday-03-resource-pressure-recovery.png`
