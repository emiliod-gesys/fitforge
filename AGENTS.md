# AGENTS.md

## Cursor Cloud specific instructions

FitForge is a **Flutter** (stable channel, 3.44.x) mobile app for Android/iOS backed by
**Supabase** (Postgres + Auth). In this headless cloud VM the app is exercised via the
**Flutter web** target and a **local Supabase** stack. Standard usage lives in `README.md`;
only the non-obvious cloud caveats are captured here.

### Flutter toolchain
- Flutter SDK lives at `~/flutter` and is on `PATH` via `~/.bashrc`. The startup update
  script runs `flutter pub get`; nothing else is needed to refresh Dart deps.
- Lint / test / analyze:
  - `flutter analyze` (lint). Reports one pre-existing **error** in `test/widget_test.dart`
    (the default generated test references a nonexistent `MyApp`).
  - `flutter test` — 223 pass. Two pre-existing failures unrelated to the environment:
    `test/widget_test.dart` (nonexistent `MyApp`) and
    `test/body_metric_health_test.dart` (a hardcoded expected `Color` no longer matches the
    theme). Do not chase these as setup problems.

### Running the app (web)
- Requires a `dart_defines.json` (git-ignored) with at least `SUPABASE_URL` and
  `SUPABASE_ANON_KEY`. Run with:
  `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define-from-file=dart_defines.json`
- First web compile takes ~1–2 min. App is then served at `http://localhost:8080`.
- Cloudflare Turnstile captcha is disabled whenever `TURNSTILE_SITE_KEY` is empty, so
  email sign-up/sign-in work locally without a captcha token.

### Local Supabase backend (start manually — never in the update script)
Docker and the `supabase` CLI are preinstalled. Bring the backend up like this:
1. Start the Docker daemon if it isn't running: `sudo dockerd > /tmp/dockerd.log 2>&1 &`
   (daemon is configured for the `fuse-overlayfs` storage driver + iptables-legacy).
2. `sudo supabase start` from the repo root.
3. From `supabase status`, use the **Publishable key** (`sb_publishable_...`) as
   `SUPABASE_ANON_KEY` and `http://127.0.0.1:54321` as `SUPABASE_URL` in `dart_defines.json`.
   Locally, email confirmation is off, so sign-up returns a session immediately.

Two non-obvious gotchas make plain `supabase start` insufficient; the migrations must be
applied and patched manually:

- **Duplicate migration version prefixes.** `supabase/migrations/` has two `015_*` and two
  `016_*` files. The CLI derives a migration version from the numeric prefix, so it hits
  `duplicate key ... schema_migrations_pkey (version 015)` and rolls back. Workaround:
  temporarily move the SQL files out of `supabase/migrations/`, run `supabase start` (clean
  empty DB), then apply every file **in sorted order** directly through psql, e.g.:
  `for f in $(ls *.sql | sort); do sudo docker exec -i supabase_db_fitforge psql -v ON_ERROR_STOP=1 -U postgres -d postgres < "$f"; done`
  then restore the files.
- **Missing table grants.** The migrations rely on Supabase's platform-level default
  privileges (they contain RLS policies but no `GRANT`s). The local stack does not apply
  those DML grants, so `authenticated` gets `permission denied for table ...` (SQLSTATE
  42501). After applying migrations, grant them (RLS still enforces per-user access):
  ```sql
  GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
  GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
  GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
  ```

The local Postgres data persists in a Docker volume across `supabase stop`/`start`, so the
schema + grants above only need to be applied once per fresh volume.
