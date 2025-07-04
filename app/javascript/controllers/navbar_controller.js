import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Initialize menu state
    this.isOpen = false
  }

  toggle() {
    this.isOpen = !this.isOpen

    if (this.isOpen) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")

    // Add animation
    this.menuTarget.style.opacity = "0"
    this.menuTarget.style.transform = "translateY(-10px)"

    requestAnimationFrame(() => {
      this.menuTarget.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
      this.menuTarget.style.opacity = "1"
      this.menuTarget.style.transform = "translateY(0)"
    })
  }

  close() {
    this.menuTarget.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
    this.menuTarget.style.opacity = "0"
    this.menuTarget.style.transform = "translateY(-10px)"

    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }, 200)
  }

  // Close menu when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.close()
      this.isOpen = false
    }
  }

  // Close menu when pressing escape key
  keydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
      this.isOpen = false
    }
  }
}
