import { Controller } from "@hotwired/stimulus"

// Progressive image loading for remote (S3) photos.
//
// Each <img> is wrapped in a container that shows a shimmering skeleton until
// the image finishes loading. On `load` the image fades in over the skeleton
// and the skeleton is removed; on `error` the skeleton is removed so the
// container's fallback background shows through.
//
// Usage:
//   <div data-controller="image-loader" class="relative ...">
//     <div data-image-loader-target="skeleton" class="absolute inset-0 img-skeleton"></div>
//     <img data-image-loader-target="image" data-action="load->image-loader#loaded error->image-loader#failed"
//          class="relative opacity-0 transition-opacity duration-500" ...>
//   </div>
export default class extends Controller {
  static targets = ["image", "skeleton"]

  connect() {
    // If the image is already cached (e.g. restored from Turbo cache or
    // prefetched on hover), `load` may have fired before Stimulus connected.
    // Check complete to avoid a lingering skeleton.
    this.imageTargets.forEach((img) => {
      if (img.complete && img.naturalWidth > 0) {
        this.reveal(img)
      }
    })
  }

  loaded(event) {
    this.reveal(event.currentTarget)
  }

  failed(event) {
    // Remove the skeleton so the container's fallback background shows.
    this.skeletonTargets.forEach((s) => s.remove())
  }

  reveal(img) {
    img.classList.remove("opacity-0")
    this.skeletonTargets.forEach((s) => s.remove())
  }
}
