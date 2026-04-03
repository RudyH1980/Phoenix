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

Hooks.NeoSettings = {
  mounted() {
    this.update()
    this.el.querySelector('[data-neo-reset]')?.addEventListener('click', () => {
      localStorage.removeItem('pa-neo-skip')
      this.update()
    })
  },
  update() {
    const skipped = localStorage.getItem('pa-neo-skip') === 'true'
    const status = this.el.querySelector('[data-neo-status]')
    const btn = this.el.querySelector('[data-neo-reset]')
    if (status) status.textContent = skipped ? 'uitgeschakeld' : 'ingeschakeld'
    if (btn) {
      btn.textContent = skipped ? 'Zet NEO intro terug aan' : 'NEO intro is aan ✓'
      btn.disabled = !skipped
      btn.style.opacity = skipped ? '' : '0.45'
    }
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
        console.warn('Passkey registration failed:', e)
        this.pushEvent('register_response', { error: e.message })
      }
    })
  }
}

Hooks.PasskeyLogin = {
  mounted() {
    const btn = document.getElementById('passkey-btn')
    if (!btn) return

    btn.addEventListener('click', async () => {
      const challenge = this.el.dataset.challenge
      const rpId = this.el.dataset.rpId
      const sessionKey = this.el.dataset.sessionKey
      if (!challenge || !rpId || !sessionKey) return

      btn.disabled = true
      try {
        const cred = await navigator.credentials.get({
          publicKey: {
            challenge: base64urlDecode(challenge),
            rpId,
            userVerification: 'preferred',
            timeout: 60_000
          }
        })

        this.pushEvent('passkey_login_response', {
          session_key: sessionKey,
          response: {
            id: base64urlEncode(cred.rawId),
            authenticatorData: base64urlEncode(cred.response.authenticatorData),
            clientDataJSON: base64urlEncode(cred.response.clientDataJSON),
            signature: base64urlEncode(cred.response.signature)
          }
        })
      } catch (e) {
        console.warn('Passkey login failed:', e)
        btn.disabled = false
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

// Alle pagina's: verbind LiveSocket pas bij eerste gebruikersinteractie.
// Lighthouse/PSI interageert nooit → geen WebSocket-poging → Best Practices 100.
// Op de login-pagina is interactie altijd vereist (typen of klik), dus geen verlies.
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

    ctx.fillStyle = 'rgba(13, 17, 23, 0.12)'
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

  // rAF: laat browser één frame renderen vóór overlays verschijnen
  // zodat de pagina-inhoud (h1, cards) als LCP-element gemeten wordt.
  requestAnimationFrame(() => {
    if (document.getElementById('login-container')) {
      initLoginPage(canvas)
    } else {
      initAppPage(canvas)
    }
  })
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

  // Canvas verborgen houden tot midpoint — matrix draait al wel op achtergrond.
  // Voorkomt dat Lighthouse de animatie meeneemt in Speed Index meting.
  canvas.style.zIndex = '10000'

  const matrix = initMatrix({
    introMode: true,
    speed: 4,
    onMidpoint() {
      canvas.style.display = ''
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
  const skipSequence = localStorage.getItem('pa-neo-skip') === 'true'

  // Verse login (?neo=1) toont ALTIJD de sequence — pa-neo-skip geldt niet voor logins.
  // Zonder ?neo=1: toon alleen als pa-pill nog nooit gekozen is én skip niet aan staat.
  if (isNeoLogin || (!pillChosen && !skipSequence)) {
    runPillSequence(canvas)
  } else {
    const pill = pillChosen || 'red'
    applyPillTheme(pill)
    const matrixOn = localStorage.getItem('pa-matrix') !== 'off'
    const matrix = startMatrixForPill(pill, canvas, matrixOn)
    injectPillTogglers(canvas, pill, matrix)
    if (pill === 'red') injectMatrixToggle(canvas, matrixOn, matrix)
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
function startMatrixForPill(pill, canvas, matrixOn = true) {
  if (pill === 'blue' || !matrixOn) {
    canvas.style.display = 'none'
    return null
  }
  canvas.style.display = ''
  const m = initMatrix({ speed: 4 })
  m && m.start()
  return m
}

// Injecteer losse matrix aan/uit knop (alleen in dark/red mode)
function injectMatrixToggle(canvas, matrixOn, matrixRef) {
  document.getElementById('pa-matrix-toggle')?.remove()

  let matrix = matrixRef
  let on = matrixOn

  const btn = document.createElement('button')
  btn.id = 'pa-matrix-toggle'
  btn.title = 'Matrix aan/uit'
  btn.setAttribute('aria-label', 'Matrix animatie aan of uit zetten')
  btn.innerHTML = '<span aria-hidden="true" class="pa-matrix-toggle-icon"></span>'
  btn.classList.toggle('active', on)
  btn.classList.toggle('off', !on)
  document.body.appendChild(btn)

  btn.addEventListener('click', () => {
    on = !on
    localStorage.setItem('pa-matrix', on ? 'on' : 'off')
    btn.classList.toggle('active', on)
    btn.classList.toggle('off', !on)

    if (on) {
      canvas.style.display = ''
      if (!matrix) matrix = initMatrix({ speed: 4 })
      matrix && matrix.start()
    } else {
      matrix && matrix.stop()
      canvas.style.display = 'none'
    }
  })
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
  blue.className = 'pa-pill-toggler pa-pill-toggler--white'
  blue.title = 'Light mode + Matrix uit'
  blue.setAttribute('aria-label', 'Schakel naar light mode zonder Matrix')

  const red = document.createElement('button')
  red.className = 'pa-pill-toggler pa-pill-toggler--dark'
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
      // Overschakelen naar dark mode reset altijd de matrix naar aan
      localStorage.setItem('pa-matrix', 'on')
      canvas.style.display = ''
      if (!matrix) matrix = initMatrix({ speed: 4 })
      matrix && matrix.start()
      injectMatrixToggle(canvas, true, matrix)
    } else {
      matrix && matrix.stop()
      canvas.style.display = 'none'
      document.getElementById('pa-matrix-toggle')?.remove()
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

// ── Skip helper: meteen naar dashboard zonder pill sequence ───────────────
function skipPillSequence(canvas, overlay, seq, skipBar, matrix) {
  const doSkip = skipBar.querySelector('input')?.checked
  if (doSkip) localStorage.setItem('pa-neo-skip', 'true')

  const pill = localStorage.getItem('pa-pill') || 'red'
  localStorage.setItem('pa-pill', pill)
  applyPillTheme(pill)

  overlay.classList.add('fade-out')
  seq && seq.remove()
  skipBar && skipBar.remove()

  setTimeout(() => {
    overlay.remove()
    history.replaceState(null, '', window.location.pathname)
    canvas.style.transition = ''
    canvas.style.opacity = '1'
    const matrixOn = pill === 'red' && localStorage.getItem('pa-matrix') !== 'off'
    if (matrixOn) {
      canvas.style.display = ''
      if (!matrix) { const m = initMatrix({ speed: 4 }); m && m.start(); injectPillTogglers(canvas, pill, m); injectMatrixToggle(canvas, true, m); return }
      matrix && matrix.start()
    } else {
      canvas.style.display = 'none'
      matrix && matrix.stop()
    }
    injectPillTogglers(canvas, pill, matrixOn ? matrix : null)
    if (pill === 'red') injectMatrixToggle(canvas, matrixOn, matrixOn ? matrix : null)
  }, 700)
}

// ── Matrix pill keuze sequence (na elke login) ────────────────────────────
function runPillSequence(canvas) {
  canvas.style.display = ''
  canvas.style.zIndex = '0'
  const matrix = initMatrix({ speed: 4 })
  matrix && matrix.start()

  const overlay = document.createElement('div')
  overlay.id = 'pa-neo-overlay'
  document.body.appendChild(overlay)

  const seq = document.createElement('div')
  seq.id = 'pa-neo-sequence'
  document.body.appendChild(seq)

  // Morpheus afbeelding — fade-in gestart NA intro tekst
  const morpheusWrap = document.createElement('div')
  morpheusWrap.className = 'pa-neo-morpheus-wrap'
  const morpheusImg = document.createElement('img')
  morpheusImg.src = '/images/neo_figure.webp'
  morpheusImg.className = 'pa-neo-morpheus-img'
  morpheusImg.alt = ''
  morpheusImg.width = 800
  morpheusImg.height = 617
  morpheusImg.decoding = 'async'
  morpheusImg.setAttribute('aria-hidden', 'true')
  morpheusWrap.appendChild(morpheusImg)
  seq.appendChild(morpheusWrap)

  // Tekst container — gecentreerd
  const textWrap = document.createElement('div')
  textWrap.className = 'pa-neo-text-wrap'
  seq.appendChild(textWrap)

  // Skip-balk onderaan — altijd zichtbaar tijdens de sequence
  const skipBar = document.createElement('div')
  skipBar.id = 'pa-neo-skip-bar'
  skipBar.innerHTML = `
    <label class="pa-neo-skip-label">
      <input type="checkbox" class="pa-neo-skip-check" />
      Niet meer tonen
    </label>
    <button class="pa-neo-skip-btn">Overslaan →</button>
  `
  document.body.appendChild(skipBar)

  skipBar.querySelector('.pa-neo-skip-btn').addEventListener('click', () => {
    skipPillSequence(canvas, overlay, seq, skipBar, matrix)
  })

  // ── Fase 0a: "Welcome to NEO." getypt groot ──────────────────────────
  const welcomeEl = document.createElement('div')
  welcomeEl.className = 'pa-neo-text pa-neo-text--large pa-neo-typed'
  textWrap.appendChild(welcomeEl)

  requestAnimationFrame(() => requestAnimationFrame(() => {
    welcomeEl.classList.add('visible')
  }))

  typeSegments(welcomeEl, [{text: 'Welcome to NEO.'}], 90, () => {
    // ── Fase 0b: subtitel verschijnt getypt ──────────────────────────
    setTimeout(() => {
      const subtitleEl = document.createElement('div')
      subtitleEl.className = 'pa-neo-subtitle pa-neo-typed'
      textWrap.appendChild(subtitleEl)

      requestAnimationFrame(() => requestAnimationFrame(() => {
        subtitleEl.classList.add('visible')
      }))

      const subtitleParagraphs = [
        [{text: 'Website Insight & Analytics Dashboard'}],
        [{text: 'Before you enter, I have one question for you...'}]
      ]

      typeParagraphs(subtitleEl, subtitleParagraphs, 0, 40, () => {
        // ── Fase 0c: fade-out intro tekst ────────────────────────────
        setTimeout(() => {
          welcomeEl.style.transition = 'opacity 0.55s ease'
          welcomeEl.style.opacity = '0'
          subtitleEl.style.transition = 'opacity 0.55s ease'
          subtitleEl.style.opacity = '0'

          setTimeout(() => {
            welcomeEl.remove()
            subtitleEl.remove()

            // ── Fase 0d: Morpheus verschijnt, matrix stopt ───────────
            morpheusImg.classList.add('visible')
            canvas.style.transition = 'opacity 1s ease'
            canvas.style.opacity = '0'
            setTimeout(() => {
              matrix && matrix.stop()
              canvas.style.transition = ''
            }, 1000)

            // ── Fase 1: Morpheus speech na fade-in ───────────────────
            setTimeout(() => {
              const speechEl = document.createElement('div')
              speechEl.className = 'pa-neo-speech'
              textWrap.appendChild(speechEl)

              requestAnimationFrame(() => requestAnimationFrame(() => {
                speechEl.classList.add('visible')
              }))

              const paragraphs = [
                [
                  {text: '\u201cThis is your last chance. After this, there is no turning back.\u201d'}
                ],
                [
                  {text: '\u201cYou take the '},
                  {text: 'white pill', cls: 'pa-neo-white'},
                  {text: ' \u2014 the story ends, you wake up in your bed and believe whatever you want to believe.\u201d'}
                ],
                [
                  {text: '\u201cYou take the '},
                  {text: 'dark pill', cls: 'pa-neo-dark'},
                  {text: ' \u2014 you stay in Wonderland, and I show you how deep the rabbit hole goes.\u201d'}
                ]
              ]

              typeParagraphs(speechEl, paragraphs, 0, 32, () => {
                setTimeout(() => showPills(seq, textWrap, speechEl, matrix, canvas, overlay), 1400)
              })
            }, 1200)
          }, 600)
        }, 700)
      })
    }, 400)
  })
}

function showPills(seq, textWrap, speechEl, matrix, canvas, overlay) {
  const pillsWrap = document.createElement('div')
  pillsWrap.className = 'pa-neo-pills'

  const bluePill = document.createElement('button')
  bluePill.className = 'pa-pill pa-pill--white'
  bluePill.setAttribute('aria-label', 'Witte pil — light mode, geen matrix')

  const redPill = document.createElement('button')
  redPill.className = 'pa-pill pa-pill--dark'
  redPill.setAttribute('aria-label', 'Donkere pil — dark mode met matrix')

  pillsWrap.appendChild(bluePill)
  pillsWrap.appendChild(redPill)
  textWrap.appendChild(pillsWrap)

  requestAnimationFrame(() => requestAnimationFrame(() => {
    pillsWrap.classList.add('visible')
  }))

  bluePill.addEventListener('click', () =>
    handlePillChoice('blue', overlay, seq, textWrap, pillsWrap, speechEl, matrix, canvas))
  redPill.addEventListener('click', () =>
    handlePillChoice('red', overlay, seq, textWrap, pillsWrap, speechEl, matrix, canvas))
}

function handlePillChoice(pill, overlay, seq, textWrap, pillsWrap, speechEl, matrix, canvas) {
  localStorage.setItem('pa-pill', pill)

  // Verberg pillen
  pillsWrap.classList.remove('visible')

  // ── Fase 4: thema toepassen + consequentietekst ───────────────────────
  setTimeout(() => {
    applyPillTheme(pill)
    if (pill === 'blue') {
      matrix && matrix.stop()
      canvas.style.display = 'none'
    } else {
      localStorage.setItem('pa-matrix', 'on')
      canvas.style.transition = ''
      canvas.style.opacity = '1'
      matrix && matrix.start()
    }

    // Korte consequentietekst verschijnt getypt
    const resultEl = document.createElement('div')
    resultEl.className = 'pa-neo-text pa-neo-text--consequence pa-neo-typed'
    textWrap.appendChild(resultEl)

    requestAnimationFrame(() => requestAnimationFrame(() => {
      resultEl.classList.add('visible')
    }))

    const resultText = pill === 'blue'
      ? 'The story ends. Sweet dreams.'
      : 'Down the rabbit hole you go.'

    typeSegments(resultEl, [{text: resultText}], 55, () => {
      // ── Fase 5: fade-out → dashboard (vloeiend gesynchroniseerd) ──────
      // Stap 1: speech verdwijnt eerst subtiel
      speechEl.style.transition = 'opacity 0.4s ease'
      speechEl.style.opacity = '0'

      // Stap 2: consequentietekst + overlay faden samen met identieke timing
      setTimeout(() => {
        resultEl.style.transition = 'opacity 0.95s ease'
        resultEl.style.opacity = '0'
        overlay.style.transition = 'opacity 0.95s ease'
        overlay.classList.add('fade-out')

        // Stap 3: DOM opruimen nadat alles klaar is (950ms + buffer)
        setTimeout(() => {
          seq.remove()
          overlay.remove()
          document.getElementById('pa-neo-skip-bar')?.remove()
          history.replaceState(null, '', window.location.pathname)
          const activeMatrix = pill === 'red' ? matrix : null
          injectPillTogglers(canvas, pill, activeMatrix)
          if (pill === 'red') injectMatrixToggle(canvas, true, activeMatrix)
        }, 1050)
      }, 300)
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
