import { Controller } from "@hotwired/stimulus"

/**
 * Local Time Controller
 *
 * Rewrites a server-rendered UTC timestamp into the browser's local timezone.
 * Attach to a <time> element carrying an ISO 8601 `datetime` attribute; the
 * element's text (a UTC fallback for no-JS) is replaced with local time.
 *
 *   <time datetime="2026-06-13T18:30:00Z" data-controller="local-time">2026-06-13 18:30</time>
 */
export default class extends Controller {
    connect() {
        const iso = this.element.getAttribute("datetime")
        if (!iso) return
        const date = new Date(iso)
        if (isNaN(date)) return
        const pad = n => String(n).padStart(2, "0")
        this.element.textContent =
            `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ` +
            `${pad(date.getHours())}:${pad(date.getMinutes())}`
    }
}
