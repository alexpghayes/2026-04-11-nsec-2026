// Paste this into your slide file.
// Dependencies: cetz:0.3.4 (or whichever you have pinned)
// Assumes your color defs are already in scope.

#import "@preview/cetz:0.3.4": canvas, draw

// ── colour aliases (already defined in your preamble) ──────────────────────
#let olive = rgb("#84994F")
#let yellow = rgb("#FFE797")
#let red = rgb("#A72703")
#let dark-teal = rgb("#365257")
#let bright = rgb("#eb811b")
#let brighter = rgb("#d6c6b7")
#let muted = rgb("#bbbbbb")
#let sand-brown = rgb("#8a6a3a")
#let sigma-diagram = canvas(length: 4.8cm, {
  import draw: *

  let col-u = sand-brown
  let col-uw = olive

  let angle-u = 58deg
  let angle-uw = 22deg
  let r = 1.0

  let u-tip = (calc.cos(angle-u), calc.sin(angle-u))
  let uw-tip = (calc.cos(angle-uw), calc.sin(angle-uw))

  let cos-theta = calc.cos(angle-u - angle-uw)
  let foot = (cos-theta * calc.cos(angle-u), cos-theta * calc.sin(angle-u))

  // axis stubs
  line((0, 0), (1.12, 0), stroke: (paint: muted, thickness: 0.6pt), mark: (end: ">", size: 0.05))
  line((0, 0), (0, 1.12), stroke: (paint: muted, thickness: 0.6pt), mark: (end: ">", size: 0.05))

  // θ_k arc
  arc((0.27, 0.1), start: angle-uw, stop: angle-u, radius: 0.30, stroke: (paint: bright, thickness: 1.5pt), fill: none)

  let mid-angle = (angle-u + angle-uw) / 2
  content(
    (0.38 * calc.cos(mid-angle), 0.38 * calc.sin(mid-angle)),
    text(fill: bright, size: 11pt)[$theta_k$],
    anchor: "center",
  )

  // uw_k vector
  line((0, 0), uw-tip, stroke: (paint: col-uw, thickness: 2pt), mark: (end: ">", size: 0.10))

  // u_k vector
  line((0, 0), u-tip, stroke: (paint: col-u, thickness: 2pt), mark: (end: ">", size: 0.10))

  // vector labels
  content(
    (u-tip.at(0) + 0.13, u-tip.at(1) + 0.04),
    text(fill: col-u, size: 14pt)[$bold(u)_k in "col"(U)$],
    anchor: "west",
  )
  content(
    (uw-tip.at(0) + 0.10, uw-tip.at(1) - 0.07),
    text(fill: col-uw, size: 14pt)[$bold(u)_k^W in "col"(U_W)$],
    anchor: "west",
  )
})
