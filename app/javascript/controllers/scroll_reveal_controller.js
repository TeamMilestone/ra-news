import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll-reveal"
export default class extends Controller {
  static targets = ["item"]
  static values = { threshold: Number, delay: Number }

  connect() {
    this.thresholdValue = this.thresholdValue || 0.1
    this.delayValue = this.delayValue || 100

    this.createObserver()
    this.observeItems()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  createObserver() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setTimeout(() => {
            entry.target.classList.add("animate-fade-in-up")
            entry.target.classList.remove("opacity-0", "translate-y-8")
          }, this.delayValue)

          this.observer.unobserve(entry.target)
        }
      })
    }, {
      threshold: this.thresholdValue,
      rootMargin: "0px 0px -50px 0px"
    })
  }

  observeItems() {
    this.itemTargets.forEach((item, index) => {
      // Add initial invisible state
      item.classList.add("opacity-0", "translate-y-8", "transition-all", "duration-600")

      // Stagger animation delay
      setTimeout(() => {
        this.observer.observe(item)
      }, index * 50)
    })
  }

  itemTargetConnected(item) {
    if (this.observer) {
      item.classList.add("opacity-0", "translate-y-8", "transition-all", "duration-600")
      this.observer.observe(item)
    }
  }

  itemTargetDisconnected(item) {
    if (this.observer) {
      this.observer.unobserve(item)
    }
  }
}
