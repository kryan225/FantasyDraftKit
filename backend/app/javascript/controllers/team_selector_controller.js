import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  connect() {
    const select = this.selectTarget
    const currentValue = select.value

    if (currentValue) {
      localStorage.setItem("selectedMyTeam", currentValue)
    } else {
      const saved = localStorage.getItem("selectedMyTeam")
      if (saved && select.querySelector(`option[value="${saved}"]`)) {
        select.value = saved
        select.form.submit()
      }
    }
  }

  save() {
    localStorage.setItem("selectedMyTeam", this.selectTarget.value)
  }
}
