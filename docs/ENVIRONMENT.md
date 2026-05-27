# ENVIRONMENT.md — Local setup & ENV reference

CLAUDE.md §7 lists the ENV vars; this file explains *what each one does*, *how to get a value*, and *how to set up a working local environment from scratch*.

---

## First-time local setup

```bash
# 1. Ruby (manage via mise/rbenv/asdf). CLAUDE.md pins 3.3.5.
#    Note: the .ruby-version file currently shows 3.4.9 — see "Open question" below.
ruby -v

# 2. Postgres 16 running locally
brew services start postgresql@16  # macOS
# or: sudo service postgresql start  # Linux

# 3. Install gems & JS deps
bundle install

# 4. Create the database
bin/rails db:create db:migrate db:seed

# 5. Copy env template
cp .env.example .env  # then fill in the values below

# 6. Start the dev process (web + tailwind watcher + solid_queue worker)
bin/dev
```

`bin/dev` reads `Procfile.dev`. Make sure all three processes start cleanly.

---

## ENV reference

### Database
| Var | Required | Notes |
|---|---|---|
| `DATABASE_URL` | dev/prod | `postgres://localhost/impact_ministry_development` in dev. Hatchbox sets this in prod. |

### Email — Postmark
| Var | Required | Notes |
|---|---|---|
| `POSTMARK_API_TOKEN` | dev/prod | Use the **test** server token in dev (sends to Postmark sandbox only). Prod uses the live transactional server. |

### Payments — Stripe
| Var | Required | Notes |
|---|---|---|
| `STRIPE_PUBLISHABLE_KEY` | when Stripe wired | Phase 3+. Test key in dev/staging. |
| `STRIPE_SECRET_KEY` | when Stripe wired | Phase 3+. Never log. Never commit. |
| `STRIPE_WEBHOOK_SECRET` | when Stripe wired | From Stripe dashboard → Webhooks → endpoint signing secret. Different per environment. |

### Feature flags
| Var | Required | Notes |
|---|---|---|
| `GIVING_ENABLED` | yes | `true` only after 501(c)(3) is granted and Stripe is live. Default `false`. |
| `PODCAST_LIVE_ENABLED` | yes | `true` once the podcast feed is approved. Default `false`. |

### Media — Cloudflare R2 (S3-compatible)
| Var | Required | Notes |
|---|---|---|
| `R2_ACCESS_KEY_ID` | yes | From R2 dashboard. |
| `R2_SECRET_ACCESS_KEY` | yes | From R2 dashboard. |
| `R2_BUCKET` | yes | `impact-ministry-dev` / `impact-ministry-prod`. Separate buckets per env. |
| `R2_ENDPOINT` | yes | `https://<account>.r2.cloudflarestorage.com`. |

### Bot defense — Cloudflare Turnstile
| Var | Required | Notes |
|---|---|---|
| `TURNSTILE_SITE_KEY` | yes | Public, embedded in form. |
| `TURNSTILE_SECRET_KEY` | yes | Server-side verification only. |

### Devotional dispatch
| Var | Required | Notes |
|---|---|---|
| `DEVOTIONAL_SEND_HOUR` | yes | Default `5`. Integer 0–23. |
| `DEVOTIONAL_TIMEZONE` | yes | Default `America/Chicago`. Mississippi is Central. |
| `ADMIN_NOTIFICATION_EMAIL` | yes | Where failsafe alerts go. Default `team@impactministry.org`. |

### Local-only conveniences
| Var | Required | Notes |
|---|---|---|
| `BIND` | optional | Bind dev server to a non-localhost address (e.g. `0.0.0.0` for WSL/Docker). |
| `PORT` | optional | Default `3000`. |

---

## Where secrets live

- **Local dev** — `.env` file in repo root, loaded by `dotenv-rails`. `.env` is gitignored. `.env.example` is committed (without values).
- **Staging / production (Hatchbox)** — Hatchbox env-var UI. Encrypted at rest.
- **Highly sensitive (Stripe live secret, Postmark live token, R2 prod keys)** — Rails encrypted credentials (`config/credentials/production.yml.enc`). Master key (`config/master.key`) lives in Hatchbox env, never committed.

If you need to add a new secret:
1. Add the var to `.env.example` with a placeholder.
2. Document it in this file under the right section.
3. Add it to Hatchbox staging + prod.
4. Reference via `Rails.application.credentials` (prod-grade) or `ENV.fetch` (dev/per-env).
5. Update CLAUDE.md §7 with the var name.

---

## Open questions to confirm with Juwon

- `.ruby-version` currently says **3.4.9**, but CLAUDE.md §2 says **3.3.5**. Which is the target? (Recommend bumping CLAUDE.md to 3.4.9 to match the installed runtime — Rails 8.1 supports it.)
- Domain — assuming `impactministry.org` for email + base URL. Confirm.
- Hatchbox vs. Kamal — CLAUDE.md says "Hatchbox (or Kamal 2)". Pick one before Phase 0.11 (CI scaffold).
- AppSignal vs. Honeybadger — pick one before Phase 4.5.
- Plausible — self-hosted or hosted? Affects DNS + ENV.
