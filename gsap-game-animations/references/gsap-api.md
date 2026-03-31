# GSAP 3.x Quick Reference

## CDN
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
```

## Core Methods

| Method | Use |
|--------|-----|
| `gsap.to(target, vars)` | Animate from current to specified values |
| `gsap.from(target, vars)` | Animate from specified values to current |
| `gsap.fromTo(target, fromVars, toVars)` | Explicit start and end |
| `gsap.set(target, vars)` | Instant property set (duration: 0) |
| `gsap.timeline(vars)` | Create sequencing container |
| `gsap.delayedCall(delay, fn)` | Call function after delay |
| `gsap.killTweensOf(target)` | Stop all tweens on target |

## Property Shortcuts

| GSAP | CSS Equivalent |
|------|----------------|
| `x` | `translateX` |
| `y` | `translateY` |
| `z` | `translateZ` |
| `rotation` | `rotateZ` |
| `rotationX` | `rotateX` |
| `rotationY` | `rotateY` |
| `scale` | `scale` |
| `opacity` | `opacity` |

## Timeline Position Parameter

| Value | Meaning |
|-------|---------|
| `">"` | After previous ends (default) |
| `"<"` | Same start as previous |
| `"<0.2"` | 0.2s after previous starts |
| `"+=0.5"` | 0.5s gap after previous |
| `"-=0.3"` | Overlap previous by 0.3s |
| `"labelName"` | At the label position |
| `"labelName+=0.2"` | 0.2s after label |

## Easing Cheat Sheet

| Ease | Character | Best For |
|------|-----------|----------|
| `power2.out` | Smooth decel | General movement |
| `power3.out` | Snappy decel | Card dealing |
| `power2.inOut` | Symmetric | Smooth transitions |
| `power3.inOut` | Symmetric snappy | Card flips |
| `power2.in` | Accelerate | Exits, falls |
| `back.out(1.3)` | Overshoot settle | Entrances, card placement |
| `back.out(1.6)` | Big overshoot | Dramatic reveals |
| `elastic.out(1, 0.5)` | Springy bounce | Scale punch settle |
| `sine.inOut` | Gentle wave | Breathing/pulse loops |

## Stagger

```js
gsap.to('.cards', {
  y: 0, opacity: 1,
  stagger: {
    each: 0.08,       // time between starts
    from: 'center',   // start from center outward
    ease: 'power2.in' // stagger timing curve
  }
});
```

## Keyframes

```js
gsap.to(element, {
  keyframes: [
    { rotation: -3, duration: 0.06 },
    { rotation: 3, duration: 0.06 },
    { rotation: 0, duration: 0.06 },
  ]
});
```

## Useful Utilities

```js
gsap.utils.toArray('.selector')  // NodeList to Array
gsap.utils.random(-10, 10)      // Random number in range
gsap.utils.wrap(0, N)           // Wrap value to 0..N range
gsap.getProperty(el, 'x')       // Read GSAP-managed value
```

## Ticker (custom render loop)

```js
gsap.ticker.add((time, deltaTime) => {
  const dt = deltaTime / 1000;
  // Custom per-frame logic
});
```

## Visibility Pause Pattern

```js
document.addEventListener('visibilitychange', () => {
  if (document.hidden) gsap.globalTimeline.pause();
  else gsap.globalTimeline.resume();
});
```
