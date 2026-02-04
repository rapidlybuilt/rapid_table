import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bulkActionSelect", "bulkActionsRowSelect", "bulkActionPerform"]

  connect() {
    this.hasBulkActionSelectTarget && this.toggleBulkActionPerform()
  }

  get selectedBulkActionIds() {
    return this.bulkActionsRowSelectTargets.filter(target => target.checked).map(target => target.value)
  }

  toggleBulkActionsSelections() {
    const value = !this.bulkActionsRowSelectTargets.every(target => target.checked)

    this.bulkActionsRowSelectTargets.forEach(target => {
      target.checked = value
    })
  }

  toggleBulkActionPerform() {
    const value = this.bulkActionSelectTarget.value && this.bulkActionsRowSelectTargets.some(target => target.checked)
    this.bulkActionPerformTarget.disabled = !value
  }

  submitBulkAction(e) {
    e.preventDefault()

    // TODO: loading indicator
    e.target.disabled = true
    const useTurboStream = e.target.dataset.turboStream
    const paramName = e.target.dataset.param || "ids"

    const formData = new FormData()
    formData.append('bulk_action', this.bulkActionSelectTarget.value)
    this.selectedBulkActionIds.forEach(id => {
      formData.append(`${paramName}[]`, id)
    })

    submitForm({
      data: formData,
      path: e.target.dataset.path,
      method: e.target.dataset.method,
      csrfToken: this.csrfToken,
      useTurboStream,
      onError: e => {
        e.target.disabled = false
        console.error("Bulk action failed:", error)
      },
    })
  }

  navigateFromSelect(e) {
    const url = e.target.value
    navigateTo(url, { useTurboStream: e.target.dataset.turboStream })
  }
}

// TODO: find a better place for this. Publish it in its own npm package?

function submitForm({ data, path, method, useTurboStream, onError }) {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

  if (useTurboStream) {
    fetch(path, {
      method,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: data,
    }).then(response => {
      // Do you need to handle non-200 responses somehow?
      return response.text()
    }).then(html => {
      Turbo.renderStreamMessage(html)
    }).catch(error => {
      onError && onError(error)
    })
  } else {
    const csrfParam = document.querySelector("meta[name='csrf-param']")?.getAttribute("content")

    // Add CSRF token to the existing FormData
    data.append('authenticity_token', csrfToken)

    // Create a temporary form and submit using the FormData
    const form = document.createElement('form')
    form.method = method || 'POST'
    form.action = path
    form.style.display = 'none'

    // Convert FormData to form inputs
    for (let [key, value] of data.entries()) {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = key
      input.value = value
      form.appendChild(input)
    }

    // Submit the form
    document.body.appendChild(form)
    form.submit()
    document.body.removeChild(form)
  }
}

function navigateTo(url, { useTurboStream, onError }) {
  if (useTurboStream) {
    fetch(url, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html'
      }
    }).then(response => {
      // Do you need to handle non-200 responses somehow?
      return response.text()
    }).then(html => {
      Turbo.renderStreamMessage(html)
    }).catch(error => {
      onError ? onError(error) : navigateTo(url)
    })
  } else if (window.Turbo) {
    window.Turbo.visit(url)
  } else {
    window.location.href = url
  }
}
