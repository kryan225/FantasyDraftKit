/**
 * Tests for BaseModalController
 *
 * These tests verify the core functionality of the base modal controller
 * that all modal implementations inherit from.
 */

import { Application } from "@hotwired/stimulus"
import BaseModalController from "../../../app/javascript/controllers/base_modal_controller"

describe("BaseModalController", () => {
  let application
  let container

  beforeEach(() => {
    // Set up a minimal DOM structure for testing
    container = document.createElement("div")
    container.innerHTML = `
      <div data-controller="base-modal" data-base-modal-target="modal" class="modal hidden">
        <div class="modal-content">
          <button type="button" data-action="click->base-modal#close">Close</button>
          <form data-action="submit->base-modal#submit">
            <input type="text" name="test" />
            <button type="submit">Submit</button>
          </form>
        </div>
      </div>
      <button data-action="click->base-modal#open">Open Modal</button>
    `
    document.body.appendChild(container)

    // Initialize Stimulus application
    application = Application.start()
    application.register("base-modal", BaseModalController)
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })

  describe("opening the modal", () => {
    test("removes 'hidden' class from modal", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")
      const openButton = container.querySelector("[data-action='click->base-modal#open']")

      expect(modal.classList.contains("hidden")).toBe(true)

      openButton.click()

      expect(modal.classList.contains("hidden")).toBe(false)
    })

    test("prevents body scrolling", () => {
      const openButton = container.querySelector("[data-action='click->base-modal#open']")

      expect(document.body.style.overflow).toBe("")

      openButton.click()

      expect(document.body.style.overflow).toBe("hidden")
    })

    test("dispatches 'opened' custom event", (done) => {
      const openButton = container.querySelector("[data-action='click->base-modal#open']")
      const controller = container.querySelector("[data-controller='base-modal']")

      controller.addEventListener("base-modal:opened", (event) => {
        expect(event.detail.modal).toBe(controller)
        done()
      })

      openButton.click()
    })
  })

  describe("closing the modal", () => {
    beforeEach(() => {
      // Open modal first
      const openButton = container.querySelector("[data-action='click->base-modal#open']")
      openButton.click()
    })

    test("adds 'hidden' class to modal", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")
      const closeButton = container.querySelector("[data-action='click->base-modal#close']")

      expect(modal.classList.contains("hidden")).toBe(false)

      closeButton.click()

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("restores body scrolling", () => {
      const closeButton = container.querySelector("[data-action='click->base-modal#close']")

      expect(document.body.style.overflow).toBe("hidden")

      closeButton.click()

      expect(document.body.style.overflow).toBe("")
    })

    test("resets form when closing", () => {
      const form = container.querySelector("form")
      const input = container.querySelector("input[name='test']")
      const closeButton = container.querySelector("[data-action='click->base-modal#close']")

      input.value = "test value"
      expect(input.value).toBe("test value")

      closeButton.click()

      expect(input.value).toBe("")
    })

    test("dispatches 'closed' custom event", (done) => {
      const closeButton = container.querySelector("[data-action='click->base-modal#close']")
      const controller = container.querySelector("[data-controller='base-modal']")

      controller.addEventListener("base-modal:closed", (event) => {
        expect(event.detail.modal).toBe(controller)
        done()
      })

      closeButton.click()
    })
  })

  describe("closing on outside click", () => {
    beforeEach(() => {
      // Open modal first
      const openButton = container.querySelector("[data-action='click->base-modal#open']")
      openButton.click()
    })

    test("closes when clicking on modal overlay", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")

      // Simulate clicking on the overlay (not the content)
      const clickEvent = new MouseEvent("click", {
        bubbles: true,
        cancelable: true,
        view: window
      })
      Object.defineProperty(clickEvent, "target", { value: modal, enumerable: true })

      modal.dispatchEvent(clickEvent)

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("does not close when clicking on modal content", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")
      const content = container.querySelector(".modal-content")

      // Simulate clicking on the content (not the overlay)
      const clickEvent = new MouseEvent("click", {
        bubbles: true,
        cancelable: true,
        view: window
      })
      Object.defineProperty(clickEvent, "target", { value: content, enumerable: true })

      modal.dispatchEvent(clickEvent)

      expect(modal.classList.contains("hidden")).toBe(false)
    })
  })

  describe("Escape key handling", () => {
    beforeEach(() => {
      // Open modal first
      const openButton = container.querySelector("[data-action='click->base-modal#open']")
      openButton.click()
    })

    test("closes modal when Escape key is pressed", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")

      expect(modal.classList.contains("hidden")).toBe(false)

      const escapeEvent = new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true
      })
      document.dispatchEvent(escapeEvent)

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("does not close on other keys", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")

      const enterEvent = new KeyboardEvent("keydown", {
        key: "Enter",
        bubbles: true
      })
      document.dispatchEvent(enterEvent)

      expect(modal.classList.contains("hidden")).toBe(false)
    })
  })

  describe("form submission handling", () => {
    beforeEach(() => {
      // Open modal first
      const openButton = container.querySelector("[data-action='click->base-modal#open']")
      openButton.click()
    })

    test("closes modal on successful Turbo submission", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")
      const controller = container.querySelector("[data-controller='base-modal']")

      // Simulate successful Turbo form submission
      const submitEndEvent = new CustomEvent("turbo:submit-end", {
        detail: {
          success: true,
          fetchResponse: {
            succeeded: true
          }
        },
        bubbles: true
      })

      controller.dispatchEvent(submitEndEvent)

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("does not close modal on failed submission", () => {
      const modal = container.querySelector("[data-base-modal-target='modal']")
      const controller = container.querySelector("[data-controller='base-modal']")

      // Simulate failed Turbo form submission
      const submitEndEvent = new CustomEvent("turbo:submit-end", {
        detail: {
          success: false,
          fetchResponse: {
            succeeded: false
          }
        },
        bubbles: true
      })

      controller.dispatchEvent(submitEndEvent)

      expect(modal.classList.contains("hidden")).toBe(false)
    })

    test("re-enables submit button on failed submission", () => {
      const submitButton = container.querySelector("button[type='submit']")
      const controller = container.querySelector("[data-controller='base-modal']")

      submitButton.disabled = true
      submitButton.dataset.originalText = "Submit"
      submitButton.textContent = "Submitting..."

      // Simulate failed Turbo form submission
      const submitEndEvent = new CustomEvent("turbo:submit-end", {
        detail: {
          success: false
        },
        bubbles: true
      })

      controller.dispatchEvent(submitEndEvent)

      expect(submitButton.disabled).toBe(false)
      expect(submitButton.textContent).toBe("Submit")
    })
  })

  describe("setSubmitLoading helper", () => {
    test("disables button and sets loading text", () => {
      const openButton = container.querySelector("[data-action='click->base-modal#open']")
      openButton.click()

      const application = Application.start()
      application.register("base-modal", BaseModalController)

      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller='base-modal']"),
        "base-modal"
      )

      const submitButton = container.querySelector("button[type='submit']")
      submitButton.textContent = "Submit"

      controller.setSubmitLoading(submitButton, "Processing...")

      expect(submitButton.disabled).toBe(true)
      expect(submitButton.textContent).toBe("Processing...")
      expect(submitButton.dataset.originalText).toBe("Submit")
    })
  })
})
