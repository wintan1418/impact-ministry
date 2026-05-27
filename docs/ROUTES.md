# ROUTES.md — URL surface

Single source of truth for the URL surface. Before adding a top-level route, check here and update.

CLAUDE.md §10 requires asking before adding new top-level routes — this file is what to check against.

---

## Public (anonymous OK)

### Marketing & content
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/` | GET | `home#show` | 1 |
| `/about` | GET | `pages#show` (slug=about) | 1 |
| `/beliefs` | GET | `pages#show` (slug=beliefs) | 1 |
| `/contact` | GET | `pages#show` (slug=contact) | 1 |
| `/privacy` | GET | `pages#show` (slug=privacy) | 1 |
| `/terms` | GET | `pages#show` (slug=terms) | 1 |
| `/pages/:slug` | GET | `pages#show` | 1 |

### Devotionals
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/devotionals` | GET | `devotionals#index` | 1 |
| `/devotionals/today` | GET | `devotionals#today` (redirect) | 1 |
| `/devotionals/:slug` | GET | `devotionals#show` | 1 |
| `/devotionals/:slug/share_card.png` | GET | `devotionals#share_card` | 2 |

### Podcast
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/podcast` | GET | `podcast_episodes#index` | 2 |
| `/podcast.rss` | GET | `podcast_episodes#feed` (format: rss) | 2 |
| `/podcast/:slug` | GET | `podcast_episodes#show` | 2 |

### Audience capture
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/subscribe` | POST | `email_subscribers#create` | 1 |
| `/unsubscribe/:token` | GET | `email_subscribers#confirm_unsubscribe` | 1 |
| `/unsubscribe/:token` | DELETE | `email_subscribers#destroy` | 1 |

### Community
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/pray` | GET | `prayer_requests#index` | 2 |
| `/pray` | POST | `prayer_requests#create` | 2 |
| `/pray/:id/prayed` | POST | `prayer_requests#prayed` (Turbo Stream) | 2 |
| `/testimonies` | GET | `testimonies#index` | 2 |
| `/testify` | GET/POST | `testimonies#new`/`#create` | 2 |
| `/partner` | GET/POST | `partnerships#new`/`#create` | 3 |
| `/contact` (form) | POST | `feedback_messages#create` | 2 |

### Resources
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/resources` | GET | `resources#index` | 3 |
| `/resources/:slug` | GET | `resources#show` | 3 |
| `/resources/:slug/download` | POST | `resources#download` | 3 |

### Giving
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/give` | GET | `giving#show` | 3 |
| `/give` | POST | `giving#create` | 3 |
| `/give/success` | GET | `giving#success` | 3 |
| `/give/cancel` | GET | `giving#cancel` | 3 |
| `/give/portal` | GET | `giving#portal` (signed-in donors) | 3 |
| `/campaigns` | GET | `donation_campaigns#index` | 4 |
| `/campaigns/:slug` | GET | `donation_campaigns#show` | 4 |

### Events
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/events` | GET | `events#index` | 4 |
| `/events/:slug` | GET | `events#show` | 4 |
| `/events/:slug/rsvp` | POST | `event_rsvps#create` | 4 |

### System
| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/up` | GET | `rails/health#show` | 0 |
| `/robots.txt` | GET | static | 1 |
| `/sitemap.xml` | GET | `sitemaps#show` | 1 |

---

## Authenticated user (`/account`)

All routes require `authenticate_user!`. Pundit policies enforce per-resource scope.

| Path | Method | Controller#action | Phase |
|---|---|---|---|
| `/account` | GET | `account/dashboards#show` | 3 |
| `/account/highlights` | GET | `account/highlights#index` | 3 |
| `/account/settings` | GET/PATCH | `account/settings#show`/`#update` | 3 |
| `/highlights` | POST/DELETE | `highlights#create`/`#destroy` | 3 |

Auth (Rails 8 generated):

| Path | Method | Controller#action |
|---|---|---|
| `/session/new` | GET | `sessions#new` |
| `/session` | POST/DELETE | `sessions#create`/`#destroy` |
| `/users/new` | GET | `users#new` |
| `/users` | POST | `users#create` |
| `/password/new` | GET | `passwords#new` |
| `/password` | POST | `passwords#create` |
| `/password/edit` | GET/PATCH | `passwords#edit`/`#update` |

(Exact paths to be confirmed against `bin/rails generate authentication` output in Phase 0.3.)

---

## Admin (`/admin`)

ActiveAdmin owns this namespace. Editor role limited to content; admin role sees everything.

- `/admin` — dashboard
- `/admin/devotionals`
- `/admin/podcast_episodes`
- `/admin/pages`
- `/admin/resources`
- `/admin/email_subscribers`
- `/admin/prayer_requests`
- `/admin/testimonies`
- `/admin/feedback_messages`
- `/admin/partnerships`
- `/admin/events` + `/admin/event_rsvps`
- `/admin/donations` *(admin only)*
- `/admin/donors` *(admin only)*
- `/admin/donation_campaigns` *(admin only)*
- `/admin/users` *(admin only)*
- `/admin/settings` *(admin only)*

---

## Webhooks & callbacks

| Path | Method | Controller#action | Notes |
|---|---|---|---|
| `/postmark/webhooks` | POST | `postmark/webhooks#create` | open/click events; signature-verified |
| `/stripe/webhooks` | POST | `stripe/webhooks#create` | signature-verified, queued |

These are intentionally **not** under `/api/`. They are external-system callbacks, not a public API. CSRF is skipped here only — never globally.

---

## Routing rules

1. **RESTful by default.** Only add a custom verb when REST genuinely doesn't fit (e.g., `/devotionals/today`, `/pray/:id/prayed`, `/give/portal`).
2. **No `/api/` namespace.** No public API in scope.
3. **Top-level slugs are scarce.** `/give`, `/pray`, `/testify`, `/partner` are intentional — short, memorable. Don't add more without product sign-off.
4. **`/account/*` is the only authenticated user namespace.** Don't sprinkle authenticated routes elsewhere.
5. **`/admin/*` is ActiveAdmin's. Don't add ad-hoc admin routes outside it.**
