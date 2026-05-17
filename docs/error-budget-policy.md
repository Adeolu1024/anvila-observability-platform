# Error Budget Policy

Service: Anvila API

Owner: Anvila DevOps team

Primary SLO: 99.5% availability over 30 days.

Error budget: 0.5% of 30 days, equal to 3.6 hours of allowed unavailability.

## Policy

At 50% consumed:

- Review recent incidents and failed deployments.
- Prioritize reliability fixes in the next sprint.
- Continue normal deployment, but watch burn rate closely.

At 75% consumed:

- Require Anvila DevOps approval for risky releases.
- Prioritize fixes for recurring alerts.
- Review rollback readiness.

At 100% consumed:

- Freeze feature releases for the affected service.
- Focus on reliability work until the service returns to budget.
- Resume feature deployment only after the team agrees the main cause has been addressed.

## Review Cadence

During Stage 6: review daily.

In normal operation: review monthly.

