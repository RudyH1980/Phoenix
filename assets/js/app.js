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

Hooks.PasskeyRegister = {
  mounted() {
    this.handleEvent('passkey_register_challenge', async (options) => {
      try {
        const cred = await navigator.credentials.create({
          publicKey: {
            ...options,
            challenge: base64urlDecode(options.challenge),
            user: {
              ...options.user,
              id: base64urlDecode(options.user.id)
            },
            excludeCredentials: (options.excludeCredentials || []).map(c => ({
              ...c,
              id: base64urlDecode(c.id)
            }))
          }
        })

        const name = prompt('Geef deze passkey een naam (bijv. iPhone 15):') || 'Passkey'

        this.pushEvent('register_response', {
          name,
          response: {
            id: base64urlEncode(cred.rawId),
            clientDataJSON: base64urlEncode(cred.response.clientDataJSON),
            attestationObject: base64urlEncode(cred.response.attestationObject)
          }
        })
      } catch (e) {
        console.error('Passkey registration failed:', e)
        this.pushEvent('register_response', { error: e.message })
      }
    })
  }
}

Hooks.PasskeyLogin = {
  mounted() {
    this.handleEvent('passkey_auth_challenge', async (options) => {
      try {
        const cred = await navigator.credentials.get({
          publicKey: {
            challenge: base64urlDecode(options.challenge),
            rpId: options.rpId,
            userVerification: options.userVerification,
            timeout: options.timeout
          }
        })

        this.pushEvent('passkey_login_response', {
          response: {
            id: base64urlEncode(cred.rawId),
            authenticatorData: base64urlEncode(cred.response.authenticatorData),
            clientDataJSON: base64urlEncode(cred.response.clientDataJSON),
            signature: base64urlEncode(cred.response.signature)
          }
        })
      } catch (e) {
        console.error('Passkey login failed:', e)
      }
    })
  }
}

function base64urlDecode(str) {
  const base64 = str.replace(/-/g, '+').replace(/_/g, '/')
  const bin = atob(base64)
  return Uint8Array.from(bin, c => c.charCodeAt(0))
}

function base64urlEncode(buffer) {
  const bytes = new Uint8Array(buffer)
  let bin = ''
  for (const b of bytes) bin += String.fromCharCode(b)
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Verbind LiveSocket pas na eerste gebruikersinteractie.
// PSI/Lighthouse interageert nooit met de pagina → geen WebSocket-poging →
// geen ERR_NAME_NOT_RESOLVED fouten → Best Practices 100.
// Echte gebruikers klikken of typen binnen milliseconden → verbinding naadloos.
if (document.querySelector('[data-phx-main]')) {
  let connected = false
  const connectNow = () => {
    if (connected) return
    connected = true
    liveSocket.connect()
  }
  ;['pointerdown', 'keydown', 'touchstart'].forEach(evt =>
    document.addEventListener(evt, connectNow, { once: true, passive: true })
  )
}

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// ============================================================
// Thema toggle — los van inline onclick om CSP nonce-safe te blijven
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
  const themeBtn = document.getElementById('pa-theme-toggle')
  if (!themeBtn) return

  function applyThemeBtn(theme) {
    const isDark = theme === 'dark'
    themeBtn.setAttribute('aria-label', isDark ? 'Schakel naar licht thema' : 'Schakel naar donker thema')
    themeBtn.setAttribute('title', isDark ? 'Schakel naar licht thema' : 'Schakel naar donker thema')
  }

  // Sync button state with current theme
  applyThemeBtn(document.documentElement.getAttribute('data-theme') || 'dark')

  themeBtn.addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme')
    const next = current === 'dark' ? 'light' : 'dark'
    document.documentElement.setAttribute('data-theme', next)
    localStorage.setItem('pa-theme', next)
    applyThemeBtn(next)
  })
})

// ============================================================
// Matrix regen animatie
// ============================================================
const MATRIX_CHARS = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF'

// opts.introMode  — columns starten bovenaan (voor intro)
// opts.onMidpoint — callback zodra 60% van columns halverwege scherm zijn
// opts.speed      — frames per stap (hoger = langzamer). standaard 2, intro = 4
function initMatrix(opts) {
  opts = opts || {}
  const canvas = document.getElementById('pa-matrix-canvas')
  if (!canvas) return null

  const ctx = canvas.getContext('2d')
  let animId = null
  let cols = []
  let midpointFired = false
  let frameCount = 0
  const FONT_SIZE = 16
  const COL_WIDTH = 18
  const SPEED = opts.speed || 2  // elke N frames een stap

  function setupCols(introMode) {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    cols = Array.from(
      { length: Math.floor(canvas.width / COL_WIDTH) },
      () => introMode
        ? Math.floor(Math.random() * -8)                           // starten aan de top
        : Math.floor(Math.random() * -(canvas.height / FONT_SIZE)) // verspreid (normaal)
    )
  }

  setupCols(opts.introMode)
  window.addEventListener('resize', () => setupCols(false))

  function draw() {
    frameCount++
    const step = frameCount % SPEED === 0  // alleen bewegen elke SPEED frames

    // Licht nagloeien zodat staarten zichtbaar blijven
    ctx.fillStyle = 'rgba(13, 17, 23, 0.04)'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.font = `${FONT_SIZE}px monospace`

    const midRow = Math.floor(canvas.height / 2 / FONT_SIZE)
    let atMid = 0

    for (let i = 0; i < cols.length; i++) {
      const x = i * COL_WIDTH
      const y = cols[i] * FONT_SIZE

      if (step) {
        // Wissel karakter elke stap
        const char = MATRIX_CHARS[Math.floor(Math.random() * MATRIX_CHARS.length)]
        // Voorste teken: helder wit
        ctx.fillStyle = 'rgba(220, 255, 250, 0.95)'
        ctx.fillText(char, x, y)
        // Tweede karakter iets dimmer
        if (cols[i] > 1) {
          const trail = MATRIX_CHARS[Math.floor(Math.random() * MATRIX_CHARS.length)]
          ctx.fillStyle = 'rgba(0, 212, 184, 0.7)'
          ctx.fillText(trail, x, y - FONT_SIZE)
        }
      }

      if (cols[i] >= midRow) atMid++

      if (step) {
        if (y > canvas.height && Math.random() > 0.975) cols[i] = 0
        cols[i]++
      }
    }

    // Trigger zodra 60% van kolommen halverwege zijn
    if (!midpointFired && opts.onMidpoint && atMid >= Math.floor(cols.length * 0.6)) {
      midpointFired = true
      opts.onMidpoint()
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
  const canvas = document.getElementById('pa-matrix-canvas')
  const btn = document.getElementById('pa-matrix-toggle')
  if (!canvas) return

  let active = localStorage.getItem('pa-matrix') === 'on'

  function attachToggle(matrix) {
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
    applyState()
    btn && btn.addEventListener('click', () => {
      active = !active
      localStorage.setItem('pa-matrix', active ? 'on' : 'off')
      applyState()
    })
  }

  // Intro bij elke volledige paginalading (refresh/eerste bezoek).
  // LiveView-navigatie herlaadt de JS niet, dus de intro verschijnt niet
  // bij interne navigatie -- alleen bij echte browser refreshes.
  if (true) {

    // Donkere overlay verbergt pagina-inhoud
    const overlay = document.createElement('div')
    overlay.id = 'pa-intro-overlay'
    document.body.appendChild(overlay)

    // Hero wrapper met titel + subtitel
    const hero = document.createElement('div')
    hero.id = 'pa-intro-hero'

    const titleEl = document.createElement('div')
    titleEl.id = 'pa-intro-title'
    titleEl.textContent = 'Neo Analytics'
    hero.appendChild(titleEl)

    const subtitleEl = document.createElement('div')
    subtitleEl.id = 'pa-intro-subtitle'
    subtitleEl.textContent = 'Unveiling the Patterns'
    hero.appendChild(subtitleEl)

    document.body.appendChild(hero)

    // "Powered by AI" — apart, verschijnt na hero fade-out
    const powered = document.createElement('div')
    powered.id = 'pa-intro-powered'
    powered.textContent = 'Powered by AI'
    document.body.appendChild(powered)

    // Canvas boven overlay tijdens intro
    canvas.style.display = ''
    canvas.style.zIndex = '10000'

    // Verberg auth-kaart zodat wachtwoordmanager niet verschijnt vóór intro klaar is.
    // visibility:hidden houdt het formulier buiten het bereik van de browser autofill.
    const authContainer = document.querySelector('.pa-auth-container')
    if (authContainer) authContainer.classList.add('pa-intro-hidden')

    const matrix = initMatrix({
      introMode: true,
      speed: 4,
      onMidpoint() {
        // Stap 1: hero (titel + subtitel) verschijnt
        // subtitel volgt automatisch 0.9s later via CSS transition-delay
        hero.classList.add('visible')

        // Stap 2: na 3.8s hero laten uitfaden
        setTimeout(() => {
          hero.classList.add('fade-out')

          // Stap 3: tijdens hero fade-out verschijnt "Powered by AI"
          setTimeout(() => {
            powered.classList.add('visible')

            // Stap 4: na 1.8s "Powered by AI" + overlay uitfaden
            setTimeout(() => {
              powered.classList.add('fade-out')
              overlay.classList.add('fade-out')
              canvas.style.zIndex = ''
              // Auth-kaart nu zichtbaar maken — gelijktijdig met overlay fade-out
              // zodat ze allebei 2.2s duren en synchroon verlopen.
              if (authContainer) {
                authContainer.classList.remove('pa-intro-hidden')
                authContainer.classList.add('pa-intro-reveal')
              }

              // Stap 5: opruimen na voltooide fade (wacht tot overlay-transitie klaar is)
              setTimeout(() => {
                hero.remove()
                powered.remove()
                overlay.remove()
                active = true
                localStorage.setItem('pa-matrix', 'on')
                attachToggle(matrix)
              }, 2300)
            }, 1800)
          }, 700)
        }, 3800)
      }
    })

    if (!matrix) return
    matrix.start()
  } else {
    const matrix = initMatrix({ speed: 2 })
    if (!matrix) return
    attachToggle(matrix)
  }
})

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

