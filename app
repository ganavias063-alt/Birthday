/* ============================================================
   BIRTHDAY WEBSITE — APP.JS
   All animations, fireworks, confetti, typewriter, etc.
   ============================================================ */

'use strict';

// ─── DOM REFS ───────────────────────────────────────────────
const loader        = document.getElementById('loader');
const fireworksCvs  = document.getElementById('fireworks-canvas');
const confettiCvs   = document.getElementById('confetti-canvas');
const fwCtx         = fireworksCvs.getContext('2d');
const cfCtx         = confettiCvs.getContext('2d');
const balloonsEl    = document.getElementById('balloons-container');
const particlesEl   = document.getElementById('particles-container');
const heartsEl      = document.getElementById('hearts-float-container');
const petalsEl      = document.getElementById('petals-container');
const musicBtn      = document.getElementById('music-btn');
const musicIcon     = document.getElementById('music-icon');
const bgMusic       = document.getElementById('bg-music');
const letterBodyEl  = document.getElementById('letter-body');
const letterSigEl   = document.getElementById('letter-signature');
const surpriseWrap  = document.getElementById('surprise-wrap');
const surpriseBtn   = document.getElementById('surprise-btn');
const finalSection  = document.getElementById('final-surprise');

// ─── STATE ──────────────────────────────────────────────────
let musicPlaying    = false;
let musicStarted    = false;
let fireworksActive = false;
let confettiActive  = false;
let confettiPieces  = [];
let fireworksList   = [];
let particlesList   = [];
let animFrame;

// ─── RESIZE CANVAS ──────────────────────────────────────────
function resizeCanvases() {
  const W = window.innerWidth, H = window.innerHeight;
  [fireworksCvs, confettiCvs].forEach(c => { c.width = W; c.height = H; });
}
resizeCanvases();
window.addEventListener('resize', resizeCanvases);

// ════════════════════════════════════════════════════════════
//  LOADER
// ════════════════════════════════════════════════════════════
function hideLoader() {
  loader.classList.add('hidden');
  setTimeout(() => {
    loader.style.display = 'none';
    onPageRevealed();
  }, 900);
}
setTimeout(hideLoader, 2200);

function onPageRevealed() {
  launchBirthayFireworks();
  launchEntryConfetti();
  startBalloons();
  startParticles();
  startPetals();
  setupScrollObserver();
  // Start letter when in view via observer
}

// ════════════════════════════════════════════════════════════
//  MUSIC
// ════════════════════════════════════════════════════════════
function tryStartMusic() {
  if (musicStarted) return;
  musicStarted = true;
  bgMusic.volume = 0.45;
  bgMusic.play().then(() => {
    musicPlaying = true;
    musicBtn.classList.add('playing');
    musicIcon.textContent = '🎵';
  }).catch(() => {
    // Autoplay blocked — wait for explicit click
    musicStarted = false;
  });
}

musicBtn.addEventListener('click', () => {
  if (!musicStarted) {
    tryStartMusic();
  } else if (musicPlaying) {
    bgMusic.pause();
    musicPlaying = false;
    musicBtn.classList.remove('playing');
    musicIcon.textContent = '🔇';
  } else {
    bgMusic.play();
    musicPlaying = true;
    musicBtn.classList.add('playing');
    musicIcon.textContent = '🎵';
  }
});

// Try music on any interaction
['scroll', 'click', 'touchstart', 'keydown'].forEach(ev =>
  document.addEventListener(ev, () => tryStartMusic(), { once: true })
);

// ════════════════════════════════════════════════════════════
//  FIREWORKS
// ════════════════════════════════════════════════════════════
class FWParticle {
  constructor(x, y, color) {
    this.x  = x; this.y  = y;
    const angle = Math.random() * Math.PI * 2;
    const speed = Math.random() * 6 + 2;
    this.vx = Math.cos(angle) * speed;
    this.vy = Math.sin(angle) * speed;
    this.alpha = 1;
    this.decay = Math.random() * 0.015 + 0.008;
    this.color = color;
    this.size  = Math.random() * 3 + 1;
    this.gravity = 0.12;
    this.tail = [];
  }
  update() {
    this.tail.push({ x: this.x, y: this.y });
    if (this.tail.length > 6) this.tail.shift();
    this.x += this.vx;
    this.y += this.vy;
    this.vy += this.gravity;
    this.vx *= 0.98;
    this.alpha -= this.decay;
  }
  draw(ctx) {
    for (let i = 0; i < this.tail.length; i++) {
      const a = (i / this.tail.length) * this.alpha * 0.5;
      ctx.globalAlpha = a;
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.arc(this.tail[i].x, this.tail[i].y, this.size * 0.5, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = this.alpha;
    ctx.fillStyle = this.color;
    ctx.shadowColor = this.color;
    ctx.shadowBlur = 8;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
  }
}

class Rocket {
  constructor() {
    this.x    = Math.random() * window.innerWidth;
    this.y    = window.innerHeight;
    this.vy   = -(Math.random() * 8 + 10);
    this.vx   = (Math.random() - 0.5) * 3;
    this.targetY = Math.random() * window.innerHeight * 0.45 + 50;
    this.exploded = false;
    this.alpha = 1;
    const h = Math.random() * 360;
    this.color = `hsl(${h},90%,65%)`;
  }
  update(parts) {
    if (!this.exploded) {
      this.x += this.vx; this.y += this.vy;
      if (this.y <= this.targetY) {
        this.explode(parts);
      }
    }
  }
  explode(parts) {
    this.exploded = true;
    const count = Math.floor(Math.random() * 60 + 80);
    for (let i = 0; i < count; i++) parts.push(new FWParticle(this.x, this.y, this.color));
  }
  draw(ctx) {
    if (!this.exploded) {
      ctx.globalAlpha = 1;
      ctx.fillStyle = this.color;
      ctx.shadowColor = this.color;
      ctx.shadowBlur = 10;
      ctx.beginPath();
      ctx.arc(this.x, this.y, 3, 0, Math.PI * 2);
      ctx.fill();
      ctx.shadowBlur = 0;
    }
  }
}

let rockets = [];
let fwParts  = [];
let fwTimer  = null;

function launchRocket() {
  rockets.push(new Rocket());
}

function fireworksLoop() {
  fwCtx.clearRect(0, 0, fireworksCvs.width, fireworksCvs.height);
  rockets.forEach(r => { r.update(fwParts); r.draw(fwCtx); });
  rockets = rockets.filter(r => !r.exploded || fwParts.length > 0);
  fwParts.forEach(p => { p.update(); p.draw(fwCtx); });
  fwParts = fwParts.filter(p => p.alpha > 0.01);
  if (fireworksActive) requestAnimationFrame(fireworksLoop);
  else { fwCtx.clearRect(0,0,fireworksCvs.width,fireworksCvs.height); }
}

function launchBirthayFireworks() {
  fireworksActive = true;
  fireworksLoop();
  // Burst launch
  for (let i = 0; i < 5; i++) setTimeout(launchRocket, i * 250);
  // Continue for 5 seconds
  let count = 0;
  fwTimer = setInterval(() => {
    launchRocket();
    count++;
    if (count > 18) {
      clearInterval(fwTimer);
      fireworksActive = false;
    }
  }, 300);
}

function launchFullFireworks() {
  fireworksActive = true;
  fireworksLoop();
  let count = 0;
  const t = setInterval(() => {
    launchRocket();
    launchRocket();
    count++;
    if (count > 50) clearInterval(t);
  }, 220);
}

// ════════════════════════════════════════════════════════════
//  CONFETTI
// ════════════════════════════════════════════════════════════
const CONFETTI_COLORS = ['#e8799a','#c9954c','#f0d080','#ffb3c6','#fff','#b388ff','#80d8ff','#a5d6a7'];

class ConfettiPiece {
  constructor(fromLeft) {
    const W = window.innerWidth;
    this.x  = fromLeft ? Math.random() * W * 0.2 : W - Math.random() * W * 0.2;
    this.y  = -20;
    this.vx = (fromLeft ? 3 : -3) + (Math.random() - 0.5) * 4;
    this.vy = Math.random() * 3 + 3;
    this.rotation = Math.random() * 360;
    this.rotV  = (Math.random() - 0.5) * 10;
    this.color = CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)];
    this.w  = Math.random() * 12 + 6;
    this.h  = Math.random() * 6 + 4;
    this.alpha = 1;
  }
  update() {
    this.x  += this.vx;
    this.y  += this.vy;
    this.vy  += 0.07;
    this.rotation += this.rotV;
    if (this.y > window.innerHeight * 0.8) this.alpha -= 0.02;
  }
  draw(ctx) {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.rotation * Math.PI / 180);
    ctx.globalAlpha = Math.max(0, this.alpha);
    ctx.fillStyle = this.color;
    ctx.fillRect(-this.w/2, -this.h/2, this.w, this.h);
    ctx.restore();
  }
}

let cfActive = false;

function confettiLoop() {
  cfCtx.clearRect(0, 0, confettiCvs.width, confettiCvs.height);
  confettiPieces.forEach(p => { p.update(); p.draw(cfCtx); });
  confettiPieces = confettiPieces.filter(p => p.alpha > 0 && p.y < window.innerHeight + 40);
  if (cfActive || confettiPieces.length > 0) requestAnimationFrame(confettiLoop);
  else cfCtx.clearRect(0,0,confettiCvs.width,confettiCvs.height);
}

function launchEntryConfetti() {
  cfActive = true;
  confettiLoop();
  // Burst from both sides
  for (let i = 0; i < 80; i++) {
    confettiPieces.push(new ConfettiPiece(true));
    confettiPieces.push(new ConfettiPiece(false));
  }
  setTimeout(() => { cfActive = false; }, 4000);
}

function launchMassiveConfetti() {
  cfActive = true;
  confettiLoop();
  let wave = 0;
  const t = setInterval(() => {
    for (let i = 0; i < 30; i++) {
      confettiPieces.push(new ConfettiPiece(Math.random() > 0.5));
    }
    wave++;
    if (wave > 40) { cfActive = false; clearInterval(t); }
  }, 80);
}

// ════════════════════════════════════════════════════════════
//  BALLOONS
// ════════════════════════════════════════════════════════════
const BALLOON_EMOJIS = ['🎈','🎈','🎈','🎀','🎊','🎉'];

function createBalloon() {
  const el = document.createElement('div');
  el.className = 'balloon';
  el.textContent = BALLOON_EMOJIS[Math.floor(Math.random() * BALLOON_EMOJIS.length)];
  el.style.left  = Math.random() * 100 + 'vw';
  const dur = (Math.random() * 10 + 12) + 's';
  el.style.animationDuration = dur;
  el.style.animationDelay    = (Math.random() * 5) + 's';
  el.style.fontSize = (Math.random() * 1.5 + 1.5) + 'rem';
  balloonsEl.appendChild(el);
  setTimeout(() => el.remove(), parseFloat(dur) * 1000 + 5000);
}

function startBalloons() {
  for (let i = 0; i < 8; i++) setTimeout(createBalloon, i * 600);
  setInterval(createBalloon, 2500);
}

// ════════════════════════════════════════════════════════════
//  PARTICLES
// ════════════════════════════════════════════════════════════
function createParticle() {
  const el = document.createElement('div');
  el.className = 'particle';
  const size = Math.random() * 8 + 3;
  el.style.width  = size + 'px';
  el.style.height = size + 'px';
  el.style.left   = Math.random() * 100 + 'vw';
  el.style.bottom = '-10px';
  const dur = (Math.random() * 15 + 10) + 's';
  el.style.animationDuration = dur;
  el.style.animationDelay    = (Math.random() * 5) + 's';
  particlesEl.appendChild(el);
  setTimeout(() => el.remove(), (parseFloat(dur) + 5) * 1000);
}

function startParticles() {
  for (let i = 0; i < 12; i++) setTimeout(createParticle, i * 400);
  setInterval(createParticle, 1200);
}

// ════════════════════════════════════════════════════════════
//  FLOWER PETALS
// ════════════════════════════════════════════════════════════
const PETAL_EMOJIS = ['🌸','🌺','🌹','🌷','🏵️'];

function createPetal() {
  const el = document.createElement('div');
  el.className = 'petal';
  el.textContent = PETAL_EMOJIS[Math.floor(Math.random() * PETAL_EMOJIS.length)];
  el.style.left  = Math.random() * 100 + 'vw';
  const dur = (Math.random() * 8 + 8) + 's';
  el.style.animationDuration = dur;
  el.style.animationDelay    = (Math.random() * 4) + 's';
  petalsEl.appendChild(el);
  setTimeout(() => el.remove(), (parseFloat(dur) + 4) * 1000);
}

function startPetals() {
  for (let i = 0; i < 10; i++) setTimeout(createPetal, i * 500);
  setInterval(createPetal, 1800);
}

// ════════════════════════════════════════════════════════════
//  FLOATING HEARTS (for final surprise)
// ════════════════════════════════════════════════════════════
function launchFloatingHearts() {
  function addHeart() {
    const el = document.createElement('div');
    el.className = 'float-heart';
    el.textContent = Math.random() > 0.5 ? '❤️' : '💕';
    el.style.left = Math.random() * 100 + 'vw';
    el.style.animationDuration = (Math.random() * 3 + 3) + 's';
    el.style.fontSize = (Math.random() * 1.5 + 1) + 'rem';
    heartsEl.appendChild(el);
    setTimeout(() => el.remove(), 6500);
  }
  let count = 0;
  const t = setInterval(() => {
    addHeart(); addHeart();
    count++;
    if (count > 60) clearInterval(t);
  }, 150);
}

// ════════════════════════════════════════════════════════════
//  SCROLL OBSERVER (fade-in)
// ════════════════════════════════════════════════════════════
let letterStarted = false;

function setupScrollObserver() {
  const opts = { threshold: 0.15 };
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('visible');
        // Start letter when letter section enters
        if (e.target.closest('#letter') && !letterStarted) {
          letterStarted = true;
          setTimeout(startTypewriter, 600);
        }
      }
    });
  }, opts);

  document.querySelectorAll('.fade-in-up').forEach(el => obs.observe(el));
}

// ════════════════════════════════════════════════════════════
//  TYPEWRITER
// ════════════════════════════════════════════════════════════
const LETTER_TEXT = `There is a girl in my life who has always been my biggest supporter. Even though she is younger than me, she takes care of me in ways that make me feel truly loved. Whenever I am hungry, she happily cooks for me. Sometimes she even feeds me herself, and those small moments mean more to me than words can express.

She is the kind of person who always stands by my side. No matter what happens, she never lets me face things alone. If anyone speaks against me or treats me unfairly, she is always there to support me. Her care, affection, and loyalty have been constant throughout my life.

People often say that a best friend is someone who understands you without explanation. I found that person in my own sister. She knows my strengths, my flaws, my struggles, and still chooses to love and support me every day.

I feel fortunate because not everyone gets a sister who is also their closest friend. The countless memories, the laughter, the care, and the bond we share are things I will always treasure.

And the girl in this story?

It's you, Pallavi.

Happy Birthday! I am truly lucky to have you as my sister, and more than that, as my best friend. ❤️`;

function startTypewriter() {
  let i = 0;
  // Add cursor
  const cursor = document.createElement('span');
  cursor.className = 'letter-cursor';
  letterBodyEl.appendChild(cursor);

  const SPEED = 22; // ms per char

  function type() {
    if (i < LETTER_TEXT.length) {
      const ch = LETTER_TEXT[i];
      // Insert char before cursor
      cursor.insertAdjacentText('beforebegin', ch);
      i++;
      // Scroll letter into view smoothly
      if (i % 80 === 0) cursor.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      // Vary speed for punctuation pauses
      const pause = (ch === '.' || ch === '!' || ch === '?') ? SPEED * 8
                  : (ch === ',') ? SPEED * 3
                  : (ch === '\n') ? SPEED * 5
                  : SPEED;
      setTimeout(type, pause);
    } else {
      // Remove cursor, show signature
      cursor.remove();
      setTimeout(() => {
        letterSigEl.classList.add('visible');
        setTimeout(() => {
          surpriseWrap.style.display = 'block';
        }, 1200);
      }, 600);
    }
  }
  type();
}

// ════════════════════════════════════════════════════════════
//  FINAL SURPRISE
// ════════════════════════════════════════════════════════════
surpriseBtn && surpriseBtn.addEventListener('click', () => {
  finalSection.style.display = 'flex';
  document.body.style.overflow = 'hidden';
  launchFullFireworks();
  launchMassiveConfetti();
  launchFloatingHearts();
  tryStartMusic();
});

// Close final surprise by clicking (optional UX)
finalSection && finalSection.addEventListener('click', (e) => {
  if (e.target === finalSection || e.target.classList.contains('surprise-overlay')) {
    // Keep it open — it's the finale
  }
});

// ════════════════════════════════════════════════════════════
//  HERO CTA — smooth scroll
// ════════════════════════════════════════════════════════════
document.querySelector('.hero-cta') && document.querySelector('.hero-cta').addEventListener('click', e => {
  e.preventDefault();
  document.querySelector('#memories').scrollIntoView({ behavior: 'smooth' });
});
