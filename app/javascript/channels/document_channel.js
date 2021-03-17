import consumer from "./consumer"

document.addEventListener('DOMContentLoaded', (event) => {
  consumer.subscriptions.create("DocumentChannel", {
    connected() {
      this.documentTable = document.querySelector('#document-table')
    },
    disconnected() {},

    received(data) {
      console.log("DOCUMENT CHANGE", data.id, data.action)

      const row = document.querySelector(`#document-row-${data.id}`)
      const container = document.querySelector(`#document-show-${data.id}`)

      if(data.action == 'created') {
        if(window.USER_PROFILE_ID && data.user_id == window.USER_PROFILE_ID) {
          this.documentTable.querySelector('tbody').insertAdjacentHTML('afterbegin', data.html)
        }
      }
      else if(row) {
        if(data.action == 'updated') {
          row.innerHTML = data.html
        }
        else if(data.action == 'deleted') {
          row.remove()
        }
      }
      else if(container) {
        container.querySelector('.body').innerHTML = data.json.body
        container.querySelector('h1').innerHTML = data.json.title
      }
    }
  })
})
