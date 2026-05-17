# Runbook: HostDown

## What This Alert Means

Blackbox Exporter could not reach the configured Anvila API endpoint for at least 2 minutes.

## Likely Causes

- Application process is down.
- Nginx is down or misconfigured.
- Server network or security group is blocking traffic.
- DNS is pointing to the wrong place.

## First 3 Investigation Steps

1. Open the Blackbox dashboard and confirm which target is failing.
2. SSH into the app server and check `systemctl status nginx`.
3. Run `curl -v` against the failing endpoint from the monitoring server.

## Resolution

Restart the failed service, fix Nginx configuration, or correct the network/security group issue.

## Rollback Guidance

Rollback if the outage started immediately after a deployment and service restart does not recover the endpoint.

## Escalation

Escalate to the Anvila DevOps team if the endpoint remains down for more than 10 minutes.

