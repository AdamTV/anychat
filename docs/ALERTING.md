# Alerting

The repository actively notifies the team when CI or deploys fail. Alerts are
defined in `.github/workflows/alert.yml` and fire when any of these workflows
completes with a `failure` conclusion:

- `Tests` - static analysis, format, complexity, and both test suites
- `Deploy to Firebase Hosting on merge` - the production Hosting/functions deploy
- `Release` - release notes and GitHub release creation
- `Rollback` - a rollback redeploy failed (treat as urgent)

## Slack setup (one time)

1. In Slack, create an incoming webhook for the channel that should receive
   alerts (Slack app directory > Incoming WebHooks, or a Slack App with the
   `incoming-webhook` scope).
2. In this repository, add the webhook URL as a repository secret:
   **Settings > Secrets and variables > Actions > New repository secret**
   - Name: `SLACK_WEBHOOK_URL`
   - Value: the `https://hooks.slack.com/services/...` URL
3. The next failing run of any workflow above posts an alert to the channel.

If the secret is missing, the alert job logs the failing run URL instead of
posting; alerting itself never fails a build.

## Extending alerts

- To alert on another workflow, add its `name:` to the `workflows:` list in
  `.github/workflows/alert.yml`.
- To route to PagerDuty, OpsGenie, or a generic incident webhook instead of
  Slack, add a step that POSTs the same JSON payload to that endpoint's
  webhook URL (stored in a repository secret).
- To alert on Cloud Functions errors in production, create a Google Cloud
  Monitoring alerting policy on the `cloudfunctions.googleapis.com`
  `function/execution_count` metric filtered to error status, with a
  notification channel (email or Slack). GCP alerting cannot be configured
  from this repository; see https://cloud.google.com/functions/docs/monitoring.

## Escalation

When an alert fires:

1. Open the run URL in the alert and read the failing step's log.
2. If the failure is a bad deploy, follow `docs/ROLLBACK.md`.
3. If the failure looks like a flaky test, the weekly `Flaky Test Detection`
   workflow reports it; add the test to `test/flaky_quarantine.txt` while it
   is being fixed.
