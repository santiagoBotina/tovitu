import { Controller } from "@hotwired/stimulus"

// Warms the browser cache for a profile's hero image as soon as the user
// hovers the card that links to it. Pet and shelter photos live in S3, so
// navigating to a profile can otherwise show a blank image for a second.
// Prefetching on hover makes the profile feel instant.
//
// The prefetch is debounced (~150ms) and cancelled on mouseleave so a quick
// pass across a grid of cards does not trigger a burst of large downloads —
// only an intentional hover that persists warms the cache.
//
// Usage:
//   <div data-controller="image-prefetch"
//        data-image-prefetch-url-value="<%= pet.primary_photo_url(variant: :large) %>"
//        data-action="mouseenter->image-prefetch#prefetch mouseleave->image-prefetch#cancel">
//     <%= link_to pet_path(pet), ... %>
//   </div>
export default class extends Controller {
  static values = { url: String }

  static debounceMs = 150

  prefetch() {
    if (this._prefetched || this.urlValue.length === 0) return
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.warm(), this.constructor.debounceMs)
  }

  cancel() {
    clearTimeout(this._timer)
  }

  disconnect() {
    this.cancel()
  }

  warm() {
    if (this._prefetched) return
    this._prefetched = true

    const img = new Image()
    img.decoding = "async"
    // Low priority so the hover prefetch never competes with critical
    // above-the-fold resources (LCP hero, CSS, fonts).
    img.fetchPriority = "low"
    img.src = this.urlValue
  }
}
