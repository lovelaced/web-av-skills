---
name: gsap-game-animations
description: Create joyful, premium game-feel animations using GSAP and Canvas 2D. Use when user asks to build interactive animations, pack openings, reveal sequences, carousels, particle effects, or celebratory/gamified UI. Triggers on "GSAP animation", "particle effect", "card reveal", "pack opening", "carousel animation", "celebration effect", "game animation", "canvas particles". Do NOT use for simple CSS transitions, static layouts, React Spring/Framer Motion projects, or general frontend work without animation focus.
metadata:
  author: burrito
  version: 1.1.0
  category: animation
  tags: [gsap, animation, particles, game-ui]
---

# GSAP Game Animations

Build premium, tactile game-feel animations using GSAP 3.x and Canvas 2D. Aim for the feel of Peggle, Balatro, Hearthstone -- animations that make the user smile.

## Setup

Load GSAP via CDN. No build tools. Works in standalone HTML or any framework.

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
```

## Core Principles

### 1. Think in Timelines, Not Tweens

Every complex animation is a choreographed sequence of **beats**. Use `gsap.timeline()` with labels so sub-animations sync naturally:

```js
const tl = gsap.timeline();
tl.addLabel('impact');
tl.to(element, { scale: 1.1, duration: 0.1, ease: 'power2.out' }, 'impact');
tl.to(flash, { opacity: 0.7, duration: 0.06 }, 'impact');
tl.to(flash, { opacity: 0, duration: 0.3, ease: 'power2.out' });
```

Position parameters (`'<'`, `'-=0.2'`, `'labelName+=0.1'`) are the secret to overlapping animations that feel alive rather than sequential and robotic.

### 2. Easing Is Everything

- **Entrances**: `back.out(1.3)` -- overshoot then settle, feels physical
- **Exits**: `power2.in` -- accelerates away naturally
- **Symmetrical motion** (flips, transitions): `power2.inOut` or `power3.inOut`
- **Impact settle**: Quick `power2.out` pop, then `elastic.out(1, 0.5)` for bounce-back
- **Two-phase motion** (spin-down, ramp-up-then-stop): Use two sequential tweens with different eases rather than one -- `power2.in` for ramp, then `power2.out` for decel
- **NEVER** use linear (`"none"`) for UI motion unless intentionally mechanical

### 3. Respect Implied Physics

- Rising objects decelerate. Falling objects accelerate.
- Ejected pieces fly in the direction of the applied force.
- Screen shake: max 2px displacement, 3-4 keyframes. Subtlety sells it.
- Scale punches sell impact: pop to 1.08-1.12x then settle. Pair with a flash.

### 4. One-Shot Effects Over Infinite Loops

Infinite CSS animations (shimmer, glow pulse) feel cheap on settled elements. Instead:
- Play the effect once when the element arrives, using a CSS class toggle with `animation-fill-mode: forwards`
- Or use GSAP's `onComplete` to add/remove classes at the right moment

## Particle System Pattern

Use Canvas 2D with **object pooling** for zero GC pressure:

```js
const POOL = 300;
const particles = Array.from({ length: POOL }, () => ({
  on: false, x: 0, y: 0, vx: 0, vy: 0,
  s: 0, life: 0, max: 0, r: 255, g: 215, b: 0
}));

function spark(x, y, vx, vy, s, life, r, g, b) {
  for (const p of particles) {
    if (p.on) continue;
    Object.assign(p, { on: true, x, y, vx, vy, s, life, max: life, r, g, b });
    return;
  }
}
```

Render with **additive blending** for natural glow accumulation:

```js
ctx.globalCompositeOperation = 'lighter';
// For each particle: draw small bright circle + larger faint circle behind it
```

Batch all `'lighter'` draws together -- switching `globalCompositeOperation` is expensive.

### Color by mood
- **Warm/celebratory**: golds, ambers, warm whites -- `[255,220,80]`, `[255,200,60]`, `[255,255,200]`
- **Cool/magical**: blues, lavenders -- `[100,180,255]`, `[220,230,255]`
- **Mix warm + cool** for "legendary" feel -- mostly gold with a few blue-white accents

## Clever Techniques

### Progressive Clip-Path Tear

Simulate a physical tear by pre-generating a jagged line and progressively revealing it with two complementary `clip-path: polygon()` elements:

```js
// Pre-generate tear line once (consistent across animation)
const tearPoints = [];
for (let i = 0; i <= STEPS; i++) {
  tearPoints.push({
    x: (i / STEPS) * width,
    y: tearY + (Math.random() - 0.5) * amplitude
  });
}

// Two elements: "still attached" shows right of cutX, "torn off" shows left of cutX
// Animate cutX from 0 to width -- the tear "travels" left to right
// The torn piece tilts away, hinged at the moving tear front
```

This creates a satisfying physical rip effect. Key: the torn piece must stay connected at the tear front during the animation, only flying off after the tear completes.

### Canvas Light Shafts

Tapered trapezoid shafts with vertical gradients, rendered on a blurred canvas, create a "divine light" / "heavenly fire" effect:

```js
// Draw each shaft as a trapezoid (wider at bottom, narrower at top)
ctx.beginPath();
ctx.moveTo(x - bottomW/2, H);      // bottom left
ctx.lineTo(x + bottomW/2, H);      // bottom right
ctx.lineTo(x + topW/2, H - height); // top right (narrower)
ctx.lineTo(x - topW/2, H - height); // top left
ctx.closePath();
ctx.fillStyle = verticalGradient;   // bright at base, transparent at top
ctx.fill();
```

Apply `filter: blur(6px)` on the canvas CSS for softness. Vary width, height, color, and speed per shaft. Center shafts should be widest/brightest.

### Glow That Follows Transparency

`drop-shadow` on elements with `clip-path` or `transform-style: preserve-3d` renders against the bounding box, not the alpha shape. Use a **blurred div behind the element** instead:

```css
.glow-bg {
  position: absolute;
  inset: 8px;
  border-radius: 14px;
  background: rgba(60,130,220,0.25);
  filter: blur(20px);
  z-index: -1;
}
```

## Performance (Mobile)

- Only animate `transform` and `opacity` -- never `width`, `height`, `top`, `left`
- Object pool particles -- never allocate in the render loop
- 300-400 particles max for 60fps on mobile
- `will-change: transform` on animated elements
- Pause on `visibilitychange` to save battery
- CSS `filter: blur()` on canvas is GPU-accelerated and cheap

## Common Pitfalls

1. **Flash overlays that don't clear**: Always `gsap.set(flash, { opacity: 0 })` on init
2. **3D card back showing after flip**: Hide the back face element (`display: none`) in the flip's `onComplete`
3. **Jerky deceleration**: Use two-phase tweens (ramp + decel) not a single ease
4. **Z-fighting with 3D transforms**: Prefer DOM reorder + scale for depth over `translateZ`
5. **Particles on top of focal element**: Render particle canvas behind the element's z-index, or spawn from edges not center
6. **Container transitions that look choppy**: Animate the parent container's `opacity` + `scale` + `y` + slight `rotation` as a unit

Consult `references/gsap-api.md` for the GSAP 3.x API quick reference.

## Examples

### Example 1: "Build a loot box opening animation"

1. Research how similar games handle this (Overwatch, Apex Legends)
2. Create a self-contained HTML file with GSAP CDN
3. Design choreography as timeline beats: box entrance, anticipation shake, lid burst, items emerge, rarity-based celebration
4. Use object-pooled canvas particles for the burst, additive blending for glow
5. Two-phase easing for the lid: resistance then release
6. Flash + screen shake + particles on rare item reveals

### Example 2: "Add a celebration effect when the user levels up"

1. Determine the trigger element and where particles should originate
2. Flash overlay (0.06s in, 0.3s fade out)
3. Ring of particles radiating from element center
4. Scale punch on the element (1.1x, elastic settle)
5. Rising sparkles from below for 1-2s ambient afterglow
6. Keep total particle count under 100 for a single burst

### Example 3: "Create a spinning prize wheel"

1. Wheel rotates via GSAP tween on `rotation` property
2. Two-phase spin: ramp-up (`power2.in`, 1s) then long decel (`power2.out`, 3-4s)
3. Calculate final rotation to land on target slice
4. Click sound simulation via screen shake on each tick mark
5. Winner celebration: flash, particles from winning slice, scale punch on result
