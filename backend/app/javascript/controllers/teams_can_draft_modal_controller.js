import BaseModalController from "./base_modal_controller"

// Connects to data-controller="teams-can-draft-modal"
export default class extends BaseModalController {
  static targets = ["modal", "position", "teamsList", "cantDraftSection", "cantDraftList"]

  show(event) {
    const button = event.currentTarget
    const position = button.dataset.position
    const teams = JSON.parse(button.dataset.teams)
    const cantDraftTeams = JSON.parse(button.dataset.teamsCantDraft || "[]")

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

    // Render can't-draft teams
    this.cantDraftListTarget.innerHTML = ""
    if (cantDraftTeams.length > 0) {
      this.cantDraftSectionTarget.style.display = "block"
      cantDraftTeams.forEach(team => {
        const item = document.createElement("a")
        item.href = `/teams/${team.id}`
        item.className = "team-list-item team-list-item--blocked"
        item.textContent = team.name

        if (team.blockers.length > 0) {
          const tooltip = document.createElement("div")
          tooltip.className = "blocker-tooltip"
          tooltip.textContent = team.blockers.join(", ")
          item.appendChild(tooltip)
        }

        this.cantDraftListTarget.appendChild(item)
      })
    } else {
      this.cantDraftSectionTarget.style.display = "none"
    }

    // Open the modal
    this.open()
  }
}
