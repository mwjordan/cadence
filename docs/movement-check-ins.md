# First Cadence check-in build

This feature work is applied to the starter-derived Cadence repository, preserving its history, Devise configuration, existing asset pipeline, and application layout. The runtime target is **Ruby 4.0.9 and Rails 8.1.4**.

## Run in a cloud workspace

Use Docker and Compose on a Linux cloud host:

```sh
docker compose up --build
```

The asset container builds the existing Turbo/Stimulus and Tailwind bundles. PostgreSQL stores account and check-in state. The Rails container runs the web app and the existing Solid Queue integration inside Puma; no extra paid service is required. Open your cloud workspace's authenticated forwarded web port and sign up.

The default web port binds only to loopback. No public HTTPS deployment is configured by this change. Database credentials in Compose are development-only and the database is not published to the host. A named volume persists its data.

For a managed proxy, Compose mounts the Linux system CA bundle for build/runtime trust. Set `CADENCE_BUILD_CA` if the combined CA bundle lives elsewhere. A read-only default Docker builder directory can be avoided with `BUILDX_CONFIG=/tmp/cadence-buildx`. Keep TLS verification enabled.

```sh
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/models spec/requests spec/services
docker compose exec web bin/rails zeitwerk:check
docker compose exec web bundle exec rubocop
docker compose exec web bin/brakeman --no-pager
```

The existing local `bin/dev` workflow is retained, with a `bin/jobs` process added for local scheduled dispatch. In Compose, Solid Queue runs inside Puma instead. Do not run a second local queue supervisor alongside that container for the same database.

## First loop

Create a movement commitment and choose an interval. **Check in now** tests the loop immediately. Done and skip finish that occurrence and begin the next interval. Later snoozes the same occurrence for five minutes. Pause cancels the open occurrence and stops dispatch; resume begins a fresh interval.

The background scheduler checks due commitments once per minute. The dashboard refreshes its Turbo Frame about every 15 seconds while visible and while you are not editing a field. A pending check-in waits for an answer rather than creating duplicates. Responses and schedules are scoped to the signed-in account and normal Rails CSRF protection remains active.

The web speech button is a foreground preview triggered by a tap. It does not meet the locked-screen voice requirement.

## Android experiment

The [Hotwire Native Android project](../android/README.md) loads the shared Rails interface. Its separate, bounded voice experiment uses Android text-to-speech and recognition to investigate locked-screen prompts and hands-free replies. The experiment starts visibly with permission and a persistent notification, runs for at most ten minutes, and stores its answers on the device. It is not yet connected to the Rails schedule or response persistence.

The [device acceptance gate](android-feasibility.md) remains required. A compiled APK does not prove background microphone availability on a real phone, and a recurring work-session activation requirement has not been accepted as product behavior.

## Starter details retained

The underlying module/database/deployment placeholder names are still the starter's existing names. Changing those or renaming existing databases is separate from this feature port. Visible sign-in and dashboard branding now says Cadence.

The existing setup request spec now stubs the rename service rather than changing real files and databases during tests. The starter's setup implementation itself is retained. The older standalone prototype and its archives remain separate for reference; its independent application history is not merged into this repository.

## Validation

Verified in the cloud workspace on Ruby 4.0.9 and Rails 8.1.4:

- Docker development image build and Compose startup, including PostgreSQL, assets, web, and the recurring worker inside Puma.
- RSpec model, request, service, and system examples pass. System examples used Capybara's Rack driver for this run; four previously skipped authentication examples remain skipped.
- A separate real Chromium run covered sign-up, creating an interval, Turbo Frame refresh, preserving a focused input, later/done/skip, pause/resume, and authenticated mobile bootstrap. The dashboard was visually inspected.
- A recurring worker generated a due check-in with no browser open; temporary test accounts were removed afterward.
- JavaScript/CSS builds, Rails eager loading, RuboCop, Brakeman, and dependency audit pass. Brakeman and the flagged rubyzip dependency were updated; the retained rename service now quotes SQL values and database identifiers through the adapter.
- The Android debug APK compiles and packages successfully. No real Android phone is attached, so locked-screen speech and hands-free replies remain unverified. Native test replies are local only.

Production deployment, mail delivery, a public HTTPS host, and native/Rails synchronization have not been configured or verified by this change.
