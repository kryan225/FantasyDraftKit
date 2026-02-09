/**
 * Tests for EditPlayerModalController
 *
 * These tests verify that clicking player names opens the edit modal
 * and that it properly extends BaseModalController functionality.
 */

import { Application } from "@hotwired/stimulus"
import EditPlayerModalController from "../../../app/javascript/controllers/edit_player_modal_controller"

describe("EditPlayerModalController", () => {
  let application
  let container

  beforeEach(() => {
    // Set up DOM structure similar to actual application
    container = document.createElement("div")
    container.innerHTML = `
      <body data-controller="edit-player-modal">
        <!-- Player link (like in _player_name.html.erb) -->
        <a
          href="#"
          data-action="click->edit-player-modal#open"
          data-player-id="123"
          data-player-name="Mike Trout"
          data-player-positions="OF"
          data-player-mlb-team="LAA"
          data-player-team-id="1"
          data-player-value="45"
          class="player-link"
        >
          <strong>Mike Trout</strong>
        </a>

        <!-- Edit Player Modal -->
        <div class="modal hidden" data-edit-player-modal-target="modal">
          <div class="modal-content">
            <button type="button" data-action="click->edit-player-modal#close">Close</button>
            <form action="/players/123" method="patch" data-edit-player-modal-target="form" data-action="submit->edit-player-modal#submit">
              <input type="text" name="player[name]" data-edit-player-modal-target="playerName" />
              <input type="text" name="player[positions]" data-edit-player-modal-target="playerPositions" />
              <input type="text" name="player[mlb_team]" data-edit-player-modal-target="playerMlbTeam" />
              <select name="player[team_id]" data-edit-player-modal-target="playerTeam">
                <option value="">-- Unowned --</option>
                <option value="1">Team Alpha</option>
                <option value="2">Team Beta</option>
              </select>
              <input type="number" name="player[calculated_value]" data-edit-player-modal-target="playerValue" />
              <button type="submit">Save Changes</button>
            </form>
          </div>
        </div>
      </body>
    `
    document.body.appendChild(container)

    // Initialize Stimulus application
    application = Application.start()
    application.register("edit-player-modal", EditPlayerModalController)
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })

  describe("clicking a player name", () => {
    test("opens the modal", () => {
      const modal = container.querySelector("[data-edit-player-modal-target='modal']")
      const playerLink = container.querySelector(".player-link")

      expect(modal.classList.contains("hidden")).toBe(true)

      playerLink.click()

      expect(modal.classList.contains("hidden")).toBe(false)
    })

    test("populates form with player data", () => {
      const playerLink = container.querySelector(".player-link")
      const nameInput = container.querySelector("[data-edit-player-modal-target='playerName']")
      const positionsInput = container.querySelector("[data-edit-player-modal-target='playerPositions']")
      const teamInput = container.querySelector("[data-edit-player-modal-target='playerMlbTeam']")
      const teamSelect = container.querySelector("[data-edit-player-modal-target='playerTeam']")
      const valueInput = container.querySelector("[data-edit-player-modal-target='playerValue']")

      playerLink.click()

      expect(nameInput.value).toBe("Mike Trout")
      expect(positionsInput.value).toBe("OF")
      expect(teamInput.value).toBe("LAA")
      expect(teamSelect.value).toBe("1")
      expect(valueInput.value).toBe("45")
    })

    test("sets form action URL correctly", () => {
      const playerLink = container.querySelector(".player-link")
      const form = container.querySelector("[data-edit-player-modal-target='form']")

      playerLink.click()

      expect(form.action).toContain("/players/123")
    })

    test("prevents default link behavior", () => {
      const playerLink = container.querySelector(".player-link")
      const clickEvent = new MouseEvent("click", {
        bubbles: true,
        cancelable: true
      })

      let defaultPrevented = false
      clickEvent.preventDefault = () => { defaultPrevented = true }

      playerLink.dispatchEvent(clickEvent)

      expect(defaultPrevented).toBe(true)
    })
  })

  describe("form validation", () => {
    beforeEach(() => {
      // Open modal first
      const playerLink = container.querySelector(".player-link")
      playerLink.click()
    })

    test("prevents submission when name is empty", () => {
      const form = container.querySelector("form")
      const nameInput = container.querySelector("[data-edit-player-modal-target='playerName']")
      const submitEvent = new Event("submit", { cancelable: true, bubbles: true })

      // Clear the name
      nameInput.value = ""

      // Mock alert
      global.alert = jest.fn()

      form.dispatchEvent(submitEvent)

      expect(global.alert).toHaveBeenCalledWith("Player name is required")
      expect(submitEvent.defaultPrevented).toBe(true)
    })

    test("prevents submission when positions is empty", () => {
      const form = container.querySelector("form")
      const positionsInput = container.querySelector("[data-edit-player-modal-target='playerPositions']")
      const submitEvent = new Event("submit", { cancelable: true, bubbles: true })

      // Clear the positions
      positionsInput.value = ""

      // Mock alert
      global.alert = jest.fn()

      form.dispatchEvent(submitEvent)

      expect(global.alert).toHaveBeenCalledWith("At least one position is required")
      expect(submitEvent.defaultPrevented).toBe(true)
    })

    test("allows submission when name and positions are filled", () => {
      const form = container.querySelector("form")
      const submitButton = container.querySelector("button[type='submit']")
      const submitEvent = new Event("submit", { cancelable: true, bubbles: true })

      // Mock alert (should not be called)
      global.alert = jest.fn()

      form.dispatchEvent(submitEvent)

      // Should not prevent default (allowing Turbo to handle submission)
      expect(global.alert).not.toHaveBeenCalled()
    })

    test("sets loading state on submit button", () => {
      const form = container.querySelector("form")
      const submitButton = container.querySelector("button[type='submit']")
      const submitEvent = new Event("submit", { cancelable: true, bubbles: true })

      submitButton.textContent = "Save Changes"

      form.dispatchEvent(submitEvent)

      expect(submitButton.disabled).toBe(true)
      expect(submitButton.textContent).toBe("Saving...")
      expect(submitButton.dataset.originalText).toBe("Save Changes")
    })
  })

  describe("inherited BaseModalController behavior", () => {
    test("closes on Escape key", () => {
      const playerLink = container.querySelector(".player-link")
      const modal = container.querySelector("[data-edit-player-modal-target='modal']")

      // Open modal
      playerLink.click()
      expect(modal.classList.contains("hidden")).toBe(false)

      // Press Escape
      const escapeEvent = new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true
      })
      document.dispatchEvent(escapeEvent)

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("closes on outside click", () => {
      const playerLink = container.querySelector(".player-link")
      const modal = container.querySelector("[data-edit-player-modal-target='modal']")

      // Open modal
      playerLink.click()
      expect(modal.classList.contains("hidden")).toBe(false)

      // Click on overlay (not content)
      const clickEvent = new MouseEvent("click", {
        bubbles: true,
        cancelable: true
      })
      Object.defineProperty(clickEvent, "target", { value: modal, enumerable: true })

      modal.dispatchEvent(clickEvent)

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("closes on close button click", () => {
      const playerLink = container.querySelector(".player-link")
      const modal = container.querySelector("[data-edit-player-modal-target='modal']")
      const closeButton = container.querySelector("[data-action='click->edit-player-modal#close']")

      // Open modal
      playerLink.click()
      expect(modal.classList.contains("hidden")).toBe(false)

      // Click close button
      closeButton.click()

      expect(modal.classList.contains("hidden")).toBe(true)
    })

    test("resets form when closing", () => {
      const playerLink = container.querySelector(".player-link")
      const modal = container.querySelector("[data-edit-player-modal-target='modal']")
      const nameInput = container.querySelector("[data-edit-player-modal-target='playerName']")
      const closeButton = container.querySelector("[data-action='click->edit-player-modal#close']")

      // Open modal and modify a field
      playerLink.click()
      nameInput.value = "Modified Name"

      // Close modal
      closeButton.click()

      // Form should be reset
      expect(nameInput.value).toBe("")
    })
  })

  describe("multiple player links", () => {
    beforeEach(() => {
      // Add another player link
      const secondLink = document.createElement("a")
      secondLink.href = "#"
      secondLink.className = "player-link"
      secondLink.setAttribute("data-action", "click->edit-player-modal#open")
      secondLink.setAttribute("data-player-id", "456")
      secondLink.setAttribute("data-player-name", "Aaron Judge")
      secondLink.setAttribute("data-player-positions", "OF")
      secondLink.setAttribute("data-player-mlb-team", "NYY")
      secondLink.setAttribute("data-player-team-id", "2")
      secondLink.setAttribute("data-player-value", "42")
      secondLink.innerHTML = "<strong>Aaron Judge</strong>"
      container.querySelector("body").appendChild(secondLink)
    })

    test("opens modal with correct data for second player", () => {
      const secondLink = container.querySelectorAll(".player-link")[1]
      const nameInput = container.querySelector("[data-edit-player-modal-target='playerName']")
      const teamSelect = container.querySelector("[data-edit-player-modal-target='playerTeam']")

      secondLink.click()

      expect(nameInput.value).toBe("Aaron Judge")
      expect(teamSelect.value).toBe("2")
    })

    test("updates form action for different players", () => {
      const firstLink = container.querySelectorAll(".player-link")[0]
      const secondLink = container.querySelectorAll(".player-link")[1]
      const form = container.querySelector("[data-edit-player-modal-target='form']")

      firstLink.click()
      expect(form.action).toContain("/players/123")

      // Close and open with different player
      const closeButton = container.querySelector("[data-action='click->edit-player-modal#close']")
      closeButton.click()

      secondLink.click()
      expect(form.action).toContain("/players/456")
    })
  })
})
