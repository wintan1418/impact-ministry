# DESIGN_SYSTEM.md — Tokens, components, templates

This file holds the design system as it gets built out. CLAUDE.md §3 (Views & styling) sets the rules; this file is where the actual components, patterns, and page templates live.

The design brief is being delivered separately. Until it is integrated below, treat CLAUDE.md as the authoritative source for tokens.

---

## Tokens (locked, from CLAUDE.md §3)

### Color
| Token | Hex | Role |
|---|---|---|
| `navy` | `#1B2A4E` | Cathedral Navy — primary, headings, anchors |
| `cream` | `#FAF7F2` | Communion Cream — page background |
| `crimson` | `#C8102E` | Sanctuary Crimson — accent, CTAs, error border |
| `linen` | `#E8DFD0` | Surface, cards, subtle dividers |
| `olive` | `#8B7355` | Olive-wood — secondary text, form help |
| `ink` | `#1F1B16` | Body text |

### Typography
- **Display** — Fraunces (variable serif). Headings, hero, devotional titles.
- **Body UI** — Inter. Navigation, buttons, forms, microcopy.
- **Long-form devotional** — Lora. Devotional body, testimonies.

### Motion
- Easing: `cubic-bezier(0.22, 1, 0.36, 1)` — exposed as CSS var `--ease-impact`.
- Default duration: `200ms` UI, `400ms` page transitions.
- **No** bouncy springs. **No** spinners. Shimmer skeletons on cream surfaces only.

### Spacing & radius
- TBD from design brief. Default to Tailwind scale until overridden.

---

## Components (to be filled in as built)

Each component, when built, lives in `app/views/shared/` (or `app/components/` if it has logic via ViewComponent). Document here:
- File path
- Props / slots
- States (default, hover, focus, disabled, loading)
- Where it's used

| Component | Path | Status | Used in |
|---|---|---|---|
| Email capture form | `app/views/shared/_email_capture.html.erb` | TODO | footer, inline, exit intent |
| Devotional card | TODO | TODO | archive, homepage |
| Prayer card | TODO | TODO | `/pray` |
| Testimony card | TODO | TODO | `/testimonies`, home |
| Button (primary / secondary / quiet) | TODO | TODO | global |
| Form field + error pattern | TODO | TODO | all forms |
| Turnstile widget | `app/views/shared/_turnstile.html.erb` | TODO | all public forms |
| Shimmer skeleton | TODO | TODO | loading states |
| Tomorrow teaser | TODO | TODO | devotional show |
| Share card (PNG template) | TODO | TODO | devotional share endpoint |

---

## Page templates (to be filled in as built)

| Page | Template | Status |
|---|---|---|
| Home `/` | `home/show.html.erb` | TODO |
| Devotional show `/devotionals/:slug` | `devotionals/show.html.erb` | TODO |
| Devotional archive `/devotionals` | `devotionals/index.html.erb` | TODO |
| Prayer wall `/pray` | `prayer_requests/index.html.erb` | TODO |
| Testimonies `/testimonies` | `testimonies/index.html.erb` | TODO |
| Give `/give` | `giving/show.html.erb` | TODO |
| Partner `/partner` | `partnerships/new.html.erb` | TODO |
| Account `/account` | `account/dashboards/show.html.erb` | TODO |
| 404 / 422 / 500 | `errors/*.html.erb` | TODO |

---

## When the design brief lands

Update this file with:
1. Final spacing scale and radius scale.
2. Component specs (with measurements / screenshots).
3. Page template specs (with measurements / screenshots / responsive breakpoints).
4. Iconography choices.
5. Photography / illustration direction.
6. Any tokens that override CLAUDE.md §3 — and update CLAUDE.md to match (CLAUDE.md §12: docs win, then CLAUDE.md gets updated).
