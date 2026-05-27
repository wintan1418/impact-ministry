import { Controller } from "@hotwired/stimulus"

// Turnstile controller.
//
// The Cloudflare widget mounts itself on any element with .cf-turnstile and,
// once the challenge is solved, injects a hidden input named
// `cf-turnstile-response` into the enclosing form. Server-side, that token is
// verified by TurnstileVerifier.
//
// This controller is intentionally minimal. It exists so we have a clean place
// to hang future hooks (e.g. resetting the widget after a failed submit, or
// reacting to a `turnstile_callback` event). For now it just logs on connect
// so devs can confirm the partial wired up correctly.
export default class extends Controller {
  connect() {
    if (window.__turnstileLogged) return
    window.__turnstileLogged = true
    // eslint-disable-next-line no-console
    console.debug("[turnstile] controller connected")
  }
}
