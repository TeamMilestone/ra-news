import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page-loader"
export default class extends Controller {
  static targets = ["loader"]

  connect() {
    // Hide loader initially
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add("hidden")
    }
  }

  show() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.remove("hidden")
      this.loaderTarget.classList.add("flex")
    }
  }

  hide() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add("hidden")
      this.loaderTarget.classList.remove("flex")
    }
  }

  // Event listeners for Turbo navigation
  beforeTurboVisit() {
    this.show()
  }

  afterTurboLoad() {
    this.hide()
  }
}
