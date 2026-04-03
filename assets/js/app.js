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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const Hooks = {}

Hooks.LineChart = {
  mounted() {
    const svg = this.el.querySelector('.pa-chart-svg')
    if (!svg) return

    const pointsRaw = svg.dataset.points
    if (!pointsRaw) return
    const points = JSON.parse(pointsRaw)

    const tooltip = document.createElement('div')
    tooltip.className = 'pa-chart-tooltip'
    tooltip.style.display = 'none'
    this.el.appendChild(tooltip)

    const line = document.createElementNS('http://www.w3.org/2000/svg', 'line')
    line.setAttribute('class', 'pa-chart-crosshair')
    line.setAttribute('y1', '0')
    line.setAttribute('y2', '100%')
    line.style.display = 'none'
    svg.appendChild(line)

    svg.addEventListener('mousemove', (e) => {
      const rect = svg.getBoundingClientRect()
      const svgW = svg.viewBox.baseVal.width || rect.width
      const svgH = svg.viewBox.baseVal.height || rect.height
      const mouseX = (e.clientX - rect.left) / rect.width * svgW

      // nearest point
      let nearest = points[0]
      let minDist = Infinity
      for (const p of points) {
        const d = Math.abs(p.x - mouseX)
        if (d < minDist) { minDist = d; nearest = p }
      }

      // crosshair
      line.setAttribute('x1', nearest.x)
      line.setAttribute('x2', nearest.x)
      line.style.display = ''

      // tooltip position (convert SVG coords to CSS %)
      const tooltipX = (nearest.x / svgW) * rect.width
      const tooltipY = (nearest.y / svgH) * rect.height
      tooltip.style.display = ''
      tooltip.style.left = `${tooltipX}px`
      tooltip.style.top = `${tooltipY - 48}px`
      tooltip.innerHTML = `<strong>${nearest.label}</strong> Weergaven: ${nearest.count}`
    })

    svg.addEventListener('mouseleave', () => {
      tooltip.style.display = 'none'
      line.style.display = 'none'
    })
  }
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// ============================================================
// Matrix regen animatie
// ============================================================
const MATRIX_CHARS = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF'

function initMatrix() {
  const canvas = document.getElementById('pa-matrix-canvas')
  if (!canvas) return null

  const ctx = canvas.getContext('2d')
  let animId = null
  let cols = []
  const FONT_SIZE = 14
  const COL_WIDTH = 16

  function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    cols = Array.from(
      { length: Math.floor(canvas.width / COL_WIDTH) },
      () => Math.floor(Math.random() * -(canvas.height / FONT_SIZE))
    )
  }

  resize()
  window.addEventListener('resize', resize)

  function draw() {
    ctx.fillStyle = 'rgba(13, 17, 23, 0.06)'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.font = `${FONT_SIZE}px monospace`

    for (let i = 0; i < cols.length; i++) {
      const char = MATRIX_CHARS[Math.floor(Math.random() * MATRIX_CHARS.length)]
      const x = i * COL_WIDTH
      const y = cols[i] * FONT_SIZE

      // Leading char: wit
      ctx.fillStyle = '#cffff9'
      ctx.fillText(char, x, y)

      // Trails: teal
      ctx.fillStyle = '#00d4b8'
      const trailChar = MATRIX_CHARS[Math.floor(Math.random() * MATRIX_CHARS.length)]
      if (cols[i] > 1) ctx.fillText(trailChar, x, y - FONT_SIZE)

      if (y > canvas.height && Math.random() > 0.975) cols[i] = 0
      cols[i]++
    }

    animId = requestAnimationFrame(draw)
  }

  return {
    start() { if (!animId) animId = requestAnimationFrame(draw) },
    stop() {
      if (animId) { cancelAnimationFrame(animId); animId = null }
      ctx.clearRect(0, 0, canvas.width, canvas.height)
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const matrix = initMatrix()
  if (!matrix) return

  const btn = document.getElementById('pa-matrix-toggle')
  const canvas = document.getElementById('pa-matrix-canvas')
  let active = localStorage.getItem('pa-matrix') === 'on'

  function applyState() {
    if (active) {
      canvas.style.display = ''
      matrix.start()
      btn && btn.classList.add('active')
      btn && btn.setAttribute('title', 'Matrix uitzetten')
    } else {
      matrix.stop()
      canvas.style.display = 'none'
      btn && btn.classList.remove('active')
      btn && btn.setAttribute('title', 'Matrix aanzetten')
    }
  }

  // Intro-animatie: één keer per sessie tonen
  const introSeen = sessionStorage.getItem('pa-intro-seen')
  if (!introSeen) {
    sessionStorage.setItem('pa-intro-seen', '1')
    runMatrixIntro(matrix, canvas, () => applyState())
  } else {
    applyState()
  }

  btn && btn.addEventListener('click', () => {
    active = !active
    localStorage.setItem('pa-matrix', active ? 'on' : 'off')
    applyState()
  })
})

function runMatrixIntro(matrix, canvas, onDone) {
  // Overlay bouwen
  const overlay = document.createElement('div')
  overlay.id = 'pa-intro-overlay'
  document.body.appendChild(overlay)

  const title = document.createElement('div')
  title.id = 'pa-intro-title'
  title.innerHTML = '<span>Phoenix</span> Analytics'
  overlay.appendChild(title)

  // Matrix starten op de intro-overlay canvas
  canvas.style.display = ''
  canvas.style.opacity = '0.7'
  matrix.start()

  // Tekst infaden na 0.6s
  setTimeout(() => { title.classList.add('visible') }, 600)

  // Na 3.2s: alles outfaden
  setTimeout(() => {
    overlay.classList.add('fade-out')
    // Na de fade: overlay verwijderen, matrix-state herstellen
    setTimeout(() => {
      overlay.remove()
      canvas.style.opacity = ''
      onDone()
    }, 1000)
  }, 3200)
}

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

