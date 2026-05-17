# Game Day Plan

## Scenario 1: Deployment Failure

Goal: Trigger a failing GitHub Actions deployment and confirm DORA metrics and CFR alerting.

Steps:

1. Push a controlled failing change to the staging branch.
2. Confirm `Deploy Staging` fails in GitHub Actions.
3. Confirm deployment failure metric updates.
4. Confirm `ChangeFailureRateHigh` alert fires.
5. Capture Slack firing notification.
6. Revert/fix the change and confirm recovery.

Evidence:

- GitHub Actions failure screenshot
- DORA dashboard screenshot
- Alertmanager alert screenshot
- Slack alert screenshot

## Scenario 2: Latency Injection

Goal: Simulate high latency and confirm SLI degradation, burn rate alerting, logs, and trace drill-down.

Steps:

1. Add temporary latency to a staging endpoint or use a test endpoint that sleeps.
2. Generate traffic against the endpoint.
3. Watch latency and availability SLI panels degrade.
4. Confirm `SLOFastBurn` fires if the error budget burns fast enough.
5. Open correlated logs in Loki.
6. Click trace ID and confirm Tempo shows the slow trace.
7. Remove latency and confirm recovery.

Evidence:

- Latency trigger screenshot
- SLO dashboard screenshot
- Loki log screenshot
- Tempo trace screenshot
- Slack firing and resolved screenshots

## Scenario 3: Resource Pressure

Goal: Simulate CPU or memory pressure and confirm warning, critical, and recovery alerts.

Steps:

1. Run a controlled CPU stress command on staging or monitoring server.
2. Confirm CPU warning fires after 5 minutes above 80%.
3. Continue pressure until critical fires after 10 minutes above 90%.
4. Stop pressure.
5. Confirm resolved Slack notifications.

Evidence:

- Stress command screenshot
- Node dashboard screenshot
- Alertmanager screenshot
- Slack firing and resolved screenshots

