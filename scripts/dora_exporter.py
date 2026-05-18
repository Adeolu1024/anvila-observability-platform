#!/usr/bin/env python3
import json
import os
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer


GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
REPOSITORY = os.environ.get("GITHUB_REPOSITORY", "hngprojects/anvila-backend")
WORKFLOWS = {
    "Deploy Staging": "staging",
    "Deploy Production": "production",
}


def parse_time(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def github_get(path):
    req = urllib.request.Request(f"https://api.github.com{path}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if GITHUB_TOKEN:
        req.add_header("Authorization", f"token {GITHUB_TOKEN}")
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.loads(response.read().decode("utf-8"))


def metric_line(name, labels, value):
    label_text = ",".join(f'{key}="{val}"' for key, val in labels.items())
    return f"{name}{{{label_text}}} {value}"


def collect_metrics():
    now = datetime.now(timezone.utc)
    runs = github_get(f"/repos/{REPOSITORY}/actions/runs?per_page=100").get(
        "workflow_runs", []
    )

    lines = [
        "# HELP anvila_deployments_total Deployment workflow runs observed in the latest GitHub Actions sample.",
        "# TYPE anvila_deployments_total gauge",
        "# HELP anvila_deployment_failures_total Failed deployment workflow runs observed in the latest GitHub Actions sample.",
        "# TYPE anvila_deployment_failures_total gauge",
        "# HELP anvila_lead_time_minutes Latest commit-to-workflow-completion lead time in minutes.",
        "# TYPE anvila_lead_time_minutes gauge",
        "# HELP anvila_deployment_frequency_7d Successful deployments in the last 7 days.",
        "# TYPE anvila_deployment_frequency_7d gauge",
        "# HELP anvila_github_actions_exporter_up Whether the DORA exporter could query GitHub successfully.",
        "# TYPE anvila_github_actions_exporter_up gauge",
        "anvila_github_actions_exporter_up 1",
    ]

    for workflow_name, environment in WORKFLOWS.items():
        matching = [run for run in runs if run.get("name") == workflow_name]
        successes = [run for run in matching if run.get("conclusion") == "success"]
        failures = [
            run
            for run in matching
            if run.get("conclusion") in {"failure", "cancelled", "timed_out", "action_required"}
        ]
        recent_successes = [
            run
            for run in successes
            if (parse_time(run.get("updated_at")) and (now - parse_time(run.get("updated_at"))).days < 7)
        ]

        labels = {"workflow": workflow_name, "environment": environment}
        lines.append(metric_line("anvila_deployments_total", labels, len(matching)))
        lines.append(metric_line("anvila_deployment_failures_total", labels, len(failures)))
        lines.append(metric_line("anvila_deployment_frequency_7d", labels, len(recent_successes)))

        latest_success = successes[0] if successes else (matching[0] if matching else None)
        if latest_success:
            commit_time = parse_time((latest_success.get("head_commit") or {}).get("timestamp"))
            completed_time = parse_time(latest_success.get("updated_at"))
            if commit_time and completed_time:
                lead_time = max((completed_time - commit_time).total_seconds() / 60, 0)
                lines.append(metric_line("anvila_lead_time_minutes", labels, round(lead_time, 2)))

    # Manual incident metric until Alertmanager history is exported.
    lines.append("anvila_incident_mttr_minutes 0")
    return "\n".join(lines) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in {"/", "/metrics"}:
            self.send_response(404)
            self.end_headers()
            return
        try:
            body = collect_metrics()
            status = 200
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError) as exc:
            body = "\n".join(
                [
                    "# HELP anvila_github_actions_exporter_up Whether the DORA exporter could query GitHub successfully.",
                    "# TYPE anvila_github_actions_exporter_up gauge",
                    "anvila_github_actions_exporter_up 0",
                    f'anvila_github_actions_exporter_error{{message="{str(exc).replace(chr(34), chr(39))}"}} 1',
                    "",
                ]
            )
            status = 200

        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        return


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "9999"))
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()
