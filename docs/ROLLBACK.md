# Rollback runbook

AnyChat Translator deploys to Firebase Hosting (channel `live`, project
`anychat-c414a`) on every merge to `main` via
`.github/workflows/firebase-hosting-merge.yml`. Because `firebase.json`
configures `hosting.frameworksBackend`, each deploy also builds and deploys
the Cloud Functions backend from the same commit.

## Automated rollback (one click)

1. Go to **Actions > Rollback** in this repository.
2. Click **Run workflow**.
3. Optionally set `target_ref` to a tag (for example `v3.0.0`), a commit SHA,
   or a branch expression such as `main~3`. Leave it empty to roll back to the
   commit before the current `main` HEAD.
4. Confirm. The workflow checks out that ref and redeploys Hosting and the
   functions backend from it.

Verify afterwards:

```bash
# Hosting answers 200
curl -sS -o /dev/null -w '%{http_code}\n' https://anychat-c414a.web.app/

# Functions health endpoint answers {"status":"ok"}
curl -sS https://us-central1-anychat-c414a.cloudfunctions.net/health
```

## Manual rollback

- **Hosting only, via the Firebase console:** Firebase Hosting keeps every
  release. Open the Firebase console > Hosting > version history, find the
  last known-good release, and choose **Roll back**. This is the fastest path
  when the bad deploy is a hosting-only change.
- **Hosting + functions, from a checkout:** check out the last known-good ref
  and deploy it the same way CI does:

  ```bash
  git checkout v3.0.0   # or the known-good commit SHA
  firebase deploy --only hosting
  ```

  With `frameworksBackend`, `--only hosting` also rebuilds and redeploys the
  functions backend. If functions were ever deployed separately
  (`firebase deploy --only functions`), roll those back too by checking out
  the same ref first.
- **Functions only:** redeploy the functions from a known-good ref with
  `firebase deploy --only functions`. Cloud Functions has no console version
  history, so the git ref is the source of truth.

## After a rollback

1. If the bad change is still on `main`, revert it (`git revert <sha>`) or
   fix forward. Do not leave `main` pointing at the broken commit, or the
   next merge will redeploy it.
2. If the rollback was triggered by a failed deploy, read the
   `Deploy to Firebase Hosting on merge` run log; the `Alerts` workflow
   (`.github/workflows/alert.yml`) also posts a Slack notification when that
   workflow fails.
3. Add a regression test that covers the failure mode; `flutter test` and
   `npm run check:flaky` must stay green.

## Hardening (optional)

Create a GitHub **environment** named `production` with required reviewers,
then add `environment: production` to the `rollback` job in
`.github/workflows/rollback.yml` so a rollback needs a second pair of eyes.
