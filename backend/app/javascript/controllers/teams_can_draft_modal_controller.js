import BaseModalController from "./base_modal_controller"

// Connects to data-controller="teams-can-draft-modal"
export default class extends BaseModalController {
  static targets = ["modal", "position", "teamsList"]

  show(event) {
    const button = event.currentTarget
    const position = button.dataset.position
    const teamsJson = button.dataset.teams

    // Parse teams data
    const teams = JSON.parse(teamsJson)

    // Update modal content
    this.positionTarget.textContent = position
    this.teamsListTarget.innerHTML = ""

    if (teams.length === 0) {
      this.teamsListTarget.innerHTML = '<p class="text-muted text-center">No teams can currently draft this position</p>'
    } else {
      teams.forEach(team => {
        const link = document.createElement("a")
        link.href = `/teams/${team.id}`
        link.className = "team-list-item"
        link.textContent = team.name
        this.teamsListTarget.appendChild(link)
      })
    }

    // Open the modal
    this.open()
  }
}
