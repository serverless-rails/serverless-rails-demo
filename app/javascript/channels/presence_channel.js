import consumer from "./consumer"

function startWatchingPresences() {
  consumer.subscriptions.create("PresenceChannel", {
    initialized() {
      this.heartbeat = this.heartbeat.bind(this)
    },

    connected() {
      if(window.CURRENT_USER_ID) {
        this.heartbeatInterval = setInterval(this.heartbeat, 60000)
        this.heartbeat()
        this.received({status: "online", id: window.CURRENT_USER_ID})
      }
    },

    disconnected() {
      clearInterval(this.heartbeatInterval)
      if(window.CURRENT_USER_ID) {
        this.received({status: "offline", id: window.CURRENT_USER_ID})
      }
    },

    heartbeat() {
      console.log("HEARTBEAT")
      this.perform('heartbeat')
    },

    received(data) {
      console.log('PRESENCE UPDATE', data.id, data.status)

      const presenceEls = document.querySelectorAll(`.user-presence.user-presence-${data.id}`)
      const fn = data.status == 'online' ? 'add' : 'remove'

      presenceEls.forEach((el) => {
        el.classList[fn]('online')
        const badge = el.querySelector('.badge')
        if(badge) { badge.innerHTML = data.status }
      })
    }
  })
}

setTimeout( startWatchingPresences, 500 )
