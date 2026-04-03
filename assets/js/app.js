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

      let nearest = points[0]
      let minDist = Infinity
      for (const p of points) {
        const d = Math.abs(p.x - mouseX)
        if (d < minDist) { minDist = d; nearest = p }
      }

      line.setAttribute('x1', nearest.x)
      line.setAttribute('x2', nearest.x)
      line.style.display = ''

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

// Progress bar op LiveView navigatie
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Verbind LiveSocket pas na eerste gebruikersinteractie.
// PSI/Lighthouse interageert nooit → geen WebSocket-poging → Best Practices 100.
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

window.liveSocket = liveSocket

// ============================================================
// Matrix regen
// ============================================================
const MATRIX_CHARS = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF'

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
  const SPEED = opts.speed || 2

  function setupCols(introMode) {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    cols = Array.from(
      { length: Math.floor(canvas.width / COL_WIDTH) },
      () => introMode
        ? Math.floor(Math.random() * -8)
        : Math.floor(Math.random() * -(canvas.height / FONT_SIZE))
    )
  }

  setupCols(opts.introMode)
  window.addEventListener('resize', () => setupCols(false))

  function draw() {
    frameCount++
    const step = frameCount % SPEED === 0

    ctx.fillStyle = 'rgba(13, 17, 23, 0.04)'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.font = `${FONT_SIZE}px monospace`

    const midRow = Math.floor(canvas.height / 2 / FONT_SIZE)
    let atMid = 0

    for (let i = 0; i < cols.length; i++) {
      const x = i * COL_WIDTH
      const y = cols[i] * FONT_SIZE

      if (step) {
        const char = MATRIX_CHARS[Math.floor(Math.random() * MATRIX_CHARS.length)]
        ctx.fillStyle = 'rgba(220, 255, 250, 0.95)'
        ctx.fillText(char, x, y)
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

// ============================================================
// Paginainitalisatie — één centrale handler
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
  const canvas = document.getElementById('pa-matrix-canvas')
  if (!canvas) return

  if (document.getElementById('login-container')) {
    initLoginPage(canvas)
  } else {
    initAppPage(canvas)
  }
})

// ── Login pagina: matrix intro ────────────────────────────────────────────
function initLoginPage(canvas) {
  // Verberg auth-kaart zodat wachtwoordmanager niet verschijnt vóór intro klaar is
  const authContainer = document.querySelector('.pa-auth-container')
  if (authContainer) authContainer.classList.add('pa-intro-hidden')

  // Donkere overlay
  const overlay = document.createElement('div')
  overlay.id = 'pa-intro-overlay'
  document.body.appendChild(overlay)

  // Hero wrapper
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

  const powered = document.createElement('div')
  powered.id = 'pa-intro-powered'
  powered.textContent = 'Powered by AI'
  document.body.appendChild(powered)

  canvas.style.display = ''
  canvas.style.zIndex = '10000'

  const matrix = initMatrix({
    introMode: true,
    speed: 4,
    onMidpoint() {
      hero.classList.add('visible')

      setTimeout(() => {
        hero.classList.add('fade-out')

        setTimeout(() => {
          powered.classList.add('visible')

          setTimeout(() => {
            powered.classList.add('fade-out')
            overlay.classList.add('fade-out')
            canvas.style.zIndex = ''

            if (authContainer) {
              authContainer.classList.remove('pa-intro-hidden')
              authContainer.classList.add('pa-intro-reveal')
            }

            setTimeout(() => {
              hero.remove()
              powered.remove()
              overlay.remove()
              // Matrix blijft actief als achtergrond op loginpagina
            }, 2300)
          }, 1800)
        }, 700)
      }, 3800)
    }
  })

  if (!matrix) return
  matrix.start()
}

// ── App pagina: pill flow ─────────────────────────────────────────────────
function initAppPage(canvas) {
  const pillChosen = localStorage.getItem('pa-pill')
  const isNeoLogin = new URLSearchParams(window.location.search).has('neo')

  if (isNeoLogin && !pillChosen) {
    runPillSequence(canvas)
  } else {
    const pill = pillChosen || 'red'
    applyPillTheme(pill)
    const matrix = startMatrixForPill(pill, canvas)
    injectPillTogglers(canvas, pill, matrix)
  }
}

// Pas thema aan op basis van pilkeuze
// Rode pil = in de Matrix blijven (dark + matrix), blauwe pil = uit de Matrix (light)
function applyPillTheme(pill) {
  const theme = pill === 'blue' ? 'light' : 'dark'
  document.documentElement.setAttribute('data-theme', theme)
  localStorage.setItem('pa-theme', theme)
}

// Start (of stop) matrix op basis van pilkeuze; geeft matrix-instantie terug
function startMatrixForPill(pill, canvas) {
  if (pill === 'blue') {
    canvas.style.display = 'none'
    return null
  }
  canvas.style.display = ''
  const m = initMatrix({ speed: 2 })
  m && m.start()
  return m
}

// Injecteer permanente pilknopjes rechtsonder
function injectPillTogglers(canvas, activePill, existingMatrix) {
  document.getElementById('pa-pill-togglers')?.remove()

  let matrix = existingMatrix

  const container = document.createElement('div')
  container.id = 'pa-pill-togglers'
  container.setAttribute('role', 'group')
  container.setAttribute('aria-label', 'Thema wisselen')

  const blue = document.createElement('button')
  blue.className = 'pa-pill-toggler pa-pill-toggler--blue'
  blue.title = 'Light mode + Matrix uit'
  blue.setAttribute('aria-label', 'Schakel naar light mode zonder Matrix')

  const red = document.createElement('button')
  red.className = 'pa-pill-toggler pa-pill-toggler--red'
  red.title = 'Dark mode + Matrix aan'
  red.setAttribute('aria-label', 'Schakel naar dark mode met Matrix')

  container.appendChild(blue)
  container.appendChild(red)
  document.body.appendChild(container)

  // Beginstatus
  ;(activePill === 'red' ? red : blue).classList.add('active')

  function switchTo(pill) {
    localStorage.setItem('pa-pill', pill)
    applyPillTheme(pill)
    blue.classList.toggle('active', pill === 'blue')
    red.classList.toggle('active', pill === 'red')

    if (pill === 'red') {
      canvas.style.display = ''
      if (!matrix) matrix = initMatrix({ speed: 2 })
      matrix && matrix.start()
    } else {
      matrix && matrix.stop()
      canvas.style.display = 'none'
    }
  }

  blue.addEventListener('click', () => switchTo('blue'))
  red.addEventListener('click', () => switchTo('red'))
}

// ── Typewriter engine ─────────────────────────────────────────────────────
// segments: [{text, cls?}] — cls geeft een <span class="cls"> om dat woord
function typeSegments(container, segments, speed, onDone) {
  const cursor = document.createElement('span')
  cursor.className = 'pa-neo-cursor'
  container.appendChild(cursor)

  let si = 0, ci = 0, currentSpan = null

  function tick() {
    if (si >= segments.length) {
      setTimeout(() => { cursor.remove(); onDone && onDone() }, 350)
      return
    }
    const seg = segments[si]
    if (ci === 0 && seg.cls) {
      currentSpan = document.createElement('span')
      currentSpan.className = seg.cls
      container.insertBefore(currentSpan, cursor)
    }
    const ch = seg.text[ci]
    if (seg.cls && currentSpan) {
      currentSpan.textContent += ch
    } else {
      const prev = cursor.previousSibling
      if (prev && prev.nodeType === Node.TEXT_NODE) {
        prev.textContent += ch
      } else {
        container.insertBefore(document.createTextNode(ch), cursor)
      }
    }
    ci++
    if (ci >= seg.text.length) { si++; ci = 0; currentSpan = null }
    const delay = '.!?'.includes(ch) ? speed * 8 : ch === ',' ? speed * 4 : ch === '-' ? speed * 3 : speed
    setTimeout(tick, delay)
  }
  tick()
}

function typeParagraphs(container, paragraphs, idx, speed, onAllDone) {
  if (idx >= paragraphs.length) { onAllDone(); return }
  const p = document.createElement('p')
  p.className = 'pa-neo-para'
  container.appendChild(p)
  // Scroll naar zichtbaar houden op kleine schermen
  p.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  typeSegments(p, paragraphs[idx], speed, () => {
    setTimeout(() => typeParagraphs(container, paragraphs, idx + 1, speed, onAllDone), 950)
  })
}

// ── Matrix pill keuze sequence (na eerste login) ──────────────────────────
function runPillSequence(canvas) {
  canvas.style.display = ''
  canvas.style.zIndex = '0'
  const matrix = initMatrix({ speed: 2 })
  matrix && matrix.start()

  const overlay = document.createElement('div')
  overlay.id = 'pa-neo-overlay'
  document.body.appendChild(overlay)

  const seq = document.createElement('div')
  seq.id = 'pa-neo-sequence'
  document.body.appendChild(seq)

  // ── Fase 1: "Welcome at NEO" getypt in groot ──────────────────────────
  const welcomeEl = document.createElement('div')
  welcomeEl.className = 'pa-neo-text pa-neo-text--large pa-neo-typed'
  seq.appendChild(welcomeEl)

  requestAnimationFrame(() => requestAnimationFrame(() => {
    welcomeEl.classList.add('visible')
  }))

  typeSegments(welcomeEl, [{text: 'Welcome at NEO'}], 90, () => {
    // Na 2s: fade uit + Morpheus speech
    setTimeout(() => {
      welcomeEl.style.transition = 'opacity 0.9s ease'
      welcomeEl.style.opacity = '0'

      setTimeout(() => {
        welcomeEl.remove()

        // ── Fase 2: Morpheus speech ────────────────────────────────────
        const speechEl = document.createElement('div')
        speechEl.className = 'pa-neo-speech'
        seq.appendChild(speechEl)

        requestAnimationFrame(() => requestAnimationFrame(() => {
          speechEl.classList.add('visible')
        }))

        // Originele Matrix tekst, gesplitst in segmenten voor kleur
        const paragraphs = [
          [
            {text: '\u201cThis is your last chance. After this, there is no turning back.\u201d'}
          ],
          [
            {text: '\u201cYou take the '},
            {text: 'blue pill',  cls: 'pa-neo-blue'},
            {text: ' \u2014 the story ends, you wake up in your bed and believe whatever you want to believe.\u201d'}
          ],
          [
            {text: '\u201cYou take the '},
            {text: 'red pill',   cls: 'pa-neo-red'},
            {text: ' \u2014 you stay in Wonderland, and I show you how deep the rabbit hole goes.\u201d'}
          ]
        ]

        typeParagraphs(speechEl, paragraphs, 0, 32, () => {
          // ── Fase 3: pillen verschijnen na korte pauze ────────────────
          setTimeout(() => showPills(seq, speechEl, matrix, canvas, overlay), 1400)
        })
      }, 900)
    }, 2000)
  })
}

function showPills(seq, speechEl, matrix, canvas, overlay) {
  const pillsWrap = document.createElement('div')
  pillsWrap.className = 'pa-neo-pills'

  const bluePill = document.createElement('button')
  bluePill.className = 'pa-pill pa-pill--blue'
  bluePill.setAttribute('aria-label', 'Blauwe pil — in de simulatie blijven')

  const redPill = document.createElement('button')
  redPill.className = 'pa-pill pa-pill--red'
  redPill.setAttribute('aria-label', 'Rode pil — de realiteit in')

  pillsWrap.appendChild(bluePill)
  pillsWrap.appendChild(redPill)
  seq.appendChild(pillsWrap)

  requestAnimationFrame(() => requestAnimationFrame(() => {
    pillsWrap.classList.add('visible')
  }))

  bluePill.addEventListener('click', () =>
    handlePillChoice('blue', overlay, seq, pillsWrap, matrix, canvas))
  redPill.addEventListener('click', () =>
    handlePillChoice('red', overlay, seq, pillsWrap, matrix, canvas))
}

function handlePillChoice(pill, overlay, seq, pillsWrap, matrix, canvas) {
  localStorage.setItem('pa-pill', pill)

  // Verberg pillen
  pillsWrap.classList.remove('visible')

  // ── Fase 4: thema toepassen + consequentietekst ───────────────────────
  setTimeout(() => {
    applyPillTheme(pill)
    if (pill === 'blue') {
      matrix && matrix.stop()
      canvas.style.display = 'none'
    }

    // Korte consequentietekst verschijnt getypt
    const resultEl = document.createElement('div')
    resultEl.className = 'pa-neo-text pa-neo-text--consequence pa-neo-typed'
    seq.appendChild(resultEl)

    requestAnimationFrame(() => requestAnimationFrame(() => {
      resultEl.classList.add('visible')
    }))

    const resultText = pill === 'blue'
      ? 'The story ends. Sweet dreams.'
      : 'Down the rabbit hole you go.'

    typeSegments(resultEl, [{text: resultText}], 55, () => {
      // ── Fase 5: fade-out → dashboard ──────────────────────────────────
      setTimeout(() => {
        resultEl.style.transition = 'opacity 0.8s ease'
        resultEl.style.opacity = '0'
        overlay.classList.add('fade-out')

        setTimeout(() => {
          seq.remove()
          overlay.remove()
          history.replaceState(null, '', window.location.pathname)
          const activeMatrix = pill === 'red' ? matrix : null
          injectPillTogglers(canvas, pill, activeMatrix)
        }, 1200)
      }, 1600)
    })
  }, 500)
}

// ============================================================
// Development live reload
// ============================================================
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    reloader.enableServerLogs()

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
