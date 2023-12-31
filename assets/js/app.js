// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { DateTime } from "../vendor/luxon"
import Sortable from "../vendor/sortable"

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach(el => liveSocket.execJS(el, el.getAttribute(attr)))
}

let Hooks = {}

Hooks.LocalTime = {
  mounted(){ this.updated() },
  updated() {
    let dt = new Date(this.el.textContent);
    let options = {hour: "2-digit", minute: "2-digit", hour12: true, timeZoneName: "short"}
    this.el.textContent = `${dt.toLocaleString('en-US', options)}`
    this.el.classList.remove("hidden")
  }
}

Hooks.LocalTimeAgo = {
  mounted(){ this.updated() },
  updated() {
    let dt = DateTime.fromISO(this.el.textContent, { zone: "UTC" }).toLocal();
    let options = {}
    this.el.textContent = `${dt.toRelative(options)}`
    this.el.classList.remove("hidden")
  }
}

Hooks.LocalTimeFull = {
  mounted(){ this.updated() },
  updated() {
    let dt = DateTime.fromISO(this.el.textContent, { zone: "UTC" }).toLocal()
    this.el.textContent = `${dt.toLocaleString(DateTime.DATETIME_FULL)}`
    this.el.classList.remove("hidden")
  }
}

Hooks.LocalTimeNow = {
  mounted(){ this.updated() },
  updated() {
    let dt = DateTime.local();
    this.el.textContent = `${dt.toLocaleString(DateTime.DATETIME_FULL)}`
    this.el.classList.remove("hidden")
  }
}

Hooks.Flash = {
  mounted(){
    let hide = () => liveSocket.execJS(this.el, this.el.getAttribute("phx-click"))
    this.timer = setTimeout(() => hide(), 8000)
    this.el.addEventListener("phx:hide-start", () => clearTimeout(this.timer))
    this.el.addEventListener("mouseover", () => {
      clearTimeout(this.timer)
      this.timer = setTimeout(() => hide(), 8000)
    })
  },
  destroyed(){ clearTimeout(this.timer) }
}

Hooks.Menu = {
  getAttr(name) {
    let val = this.el.getAttribute(name)
    if (val === null) { throw (new Error(`no ${name} attribute configured for menu`)) }
    return val
  },
  reset() {
    this.enabled = false
    this.activeClass = this.getAttr("data-active-class")
    this.deactivate(this.menuItems())
    this.activeItem = null
    window.removeEventListener("keydown", this.handleKeyDown)
  },
  destroyed() { this.reset() },
  mounted() {
    this.menuItemsContainer = document.querySelector(`[aria-labelledby="${this.el.id}"]`)
    this.reset()
    this.handleKeyDown = (e) => this.onKeyDown(e)
    this.el.addEventListener("keydown", e => {
      if ((e.key === "Enter" || e.key === " ") && e.currentTarget.isSameNode(this.el)) {
        this.enabled = true
      }
    })
    this.el.addEventListener("click", e => {
      if (!e.currentTarget.isSameNode(this.el)) { return }

      window.addEventListener("keydown", this.handleKeyDown)
      // disable if button clicked and click was not a keyboard event
      if (this.enabled) {
        window.requestAnimationFrame(() => this.activate(0))
      }
    })
    this.menuItemsContainer.addEventListener("phx:hide-start", () => this.reset())
  },
  activate(index, fallbackIndex) {
    let menuItems = this.menuItems()
    this.activeItem = menuItems[index] || menuItems[fallbackIndex]
    this.activeItem.classList.add(this.activeClass)
    this.activeItem.focus()
  },
  deactivate(items) { items.forEach(item => item.classList.remove(this.activeClass)) },
  menuItems() { return Array.from(this.menuItemsContainer.querySelectorAll("[role=menuitem]")) },
  onKeyDown(e) {
    if (e.key === "Escape") {
      document.body.click()
      this.el.focus()
      this.reset()
    } else if (e.key === "Enter" && !this.activeItem) {
      this.activate(0)
    } else if (e.key === "Enter") {
      this.activeItem.click()
    }
    if (e.key === "ArrowDown") {
      e.preventDefault()
      let menuItems = this.menuItems()
      this.deactivate(menuItems)
      this.activate(menuItems.indexOf(this.activeItem) + 1, 0)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      let menuItems = this.menuItems()
      this.deactivate(menuItems)
      this.activate(menuItems.indexOf(this.activeItem) - 1, menuItems.length - 1)
    } else if (e.key === "Tab") {
      e.preventDefault()
    }
  }
}

Hooks.Sortable = {
  mounted(){
    let group = this.el.dataset.group
    let isDragging = false
    this.el.addEventListener("focusout", e => isDragging && e.stopImmediatePropagation())
    let sorter = new Sortable(this.el, {
      group: group ? {name: group, pull: true, put: true} : undefined,
      animation: 150,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      onStart: e => isDragging = true, // prevent phx-blur from firing while dragging
      onEnd: e => {
        isDragging = false
        let params = {old: e.oldIndex, new: e.newIndex, to: e.to.dataset, ...e.item.dataset}
        this.pushEventTo(this.el, this.el.dataset["drop"] || "reposition", params)
      }
    })
  }
}

Hooks.SortableInputsFor = {
  mounted(){
    let group = this.el.dataset.group
    let sorter = new Sortable(this.el, {
      group: group ? {name: group, pull: true, put: true} : undefined,
      animation: 150,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      handle: "[data-handle]",
      forceFallback: true,
      onEnd: e => {
        this.el.closest("form").querySelector("input").dispatchEvent(new Event("input", {bubbles: true}))
      }
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.getSocket().onOpen(() => execJS("#connection-status", "js-hide"))
liveSocket.getSocket().onError(() => execJS("#connection-status", "js-show"))
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

