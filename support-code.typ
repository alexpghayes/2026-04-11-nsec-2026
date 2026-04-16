#import "@preview/polylux:0.4.0": *
#import "@preview/cetz:0.3.4": canvas, draw
#import "theme.typ": *

// ══════════════════════════════════════════════════════════════════════════════
// ── ANNOTATION POSITIONS ──────────────────────────────────────────────────────
//
//  All coordinates are in CeTZ world units at length: 1.3cm.
//
//  anno-a-top  (arrow: "Which traits? How many?")
//    label-pos   — where the text box is placed
//    arrow-start — where the bezier tail begins (near the text)
//    ctrl1/ctrl2 — bezier control points
//    arrow-end   — arrowhead destination (points at something in panel-a)
//
//  anno-a-bottom  (arrow: "Traits must be binary and exclusive")
//    Same fields; points at the W dimension label beneath the matrix.
//
//  Tip: increase label-pos.x to move the label right, label-pos.y to move up.
//       Adjust arrow-end to change what the arrowhead points at.
// ══════════════════════════════════════════════════════════════════════════════

// Top annotation — "Which traits? How many?"
#let anno-a-top-cfg = (
  label-pos: (4.7, 4.35), // text anchor position
  label-anchor: "south",
  arrow-start: (6.95, 4.53), // tail of bezier (near label)
  ctrl1: (7.4, 4.5),
  ctrl2: (7.2, 5),
  arrow-end: (7.25, 4.9), // arrowhead target
)

// Bottom annotation — "Traits must be binary and exclusive"
#let anno-a-bottom-cfg = (
  label-pos: (3.35, -0.95), // text anchor position (world coords)
  label-anchor: "north",
  arrow-start: (4.45, -0.75), // tail of bezier
  ctrl1: (4.9, -0.75),
  ctrl2: (5.15, -0.50),
  arrow-end: (5.05, -0.53), // arrowhead target
)

#let trait-color(t) = if t == 1 { olive } else if t == 2 { bright } else { red }

#let draw-matrix(origin, rows, cell-w, cell-h, stroke-style, row-colors: none, col-colors: none) = {
  import draw: *
  let n-rows = rows.len()
  let n-cols = rows.at(0).len()
  let (ox, oy) = origin
  let total-w = cell-w * n-cols
  let total-h = cell-h * n-rows
  rect((ox, oy), (ox + total-w, oy + total-h), stroke: stroke-style)
  for i in range(1, n-rows) {
    line((ox, oy + i * cell-h), (ox + total-w, oy + i * cell-h), stroke: (
      paint: stroke-style.paint,
      thickness: 0.5pt,
      dash: "dotted",
    ))
  }
  for j in range(1, n-cols) {
    line((ox + j * cell-w, oy), (ox + j * cell-w, oy + total-h), stroke: (
      paint: stroke-style.paint,
      thickness: 0.5pt,
      dash: "dotted",
    ))
  }
  for (i, row) in rows.enumerate() {
    for (j, val) in row.enumerate() {
      let text-color = if row-colors != none { row-colors.at(i) } else if col-colors != none { col-colors.at(j) } else {
        stroke-style.paint
      }
      let cx = ox + j * cell-w + cell-w / 2
      let cy = oy + (n-rows - 1 - i) * cell-h + cell-h / 2
      content((cx, cy), text(fill: text-color, size: 12pt)[$#val$], anchor: "center")
    }
  }
}

#let cw = 0.62
#let ch = 0.62
#let a-gap = 0.75
#let yw = 3 * cw
#let aw = 5 * cw
#let ww = 3 * cw
#let mat-h = 5 * ch
#let y-ox-l = 0.0
#let a-ox-l = y-ox-l + yw + a-gap
#let w-ox-l = a-ox-l + aw + a-gap

// ── Shared annotation helper ──────────────────────────────────────────────────
#let anno(cfg, body) = {
  import draw: *
  content(cfg.label-pos, text(fill: sand-brown, size: 12pt)[#body], anchor: cfg.label-anchor)
  bezier(
    cfg.arrow-start,
    cfg.arrow-end,
    cfg.ctrl1,
    cfg.ctrl2,
    stroke: (paint: sand-brown, thickness: 0.8pt),
    mark: (end: ">", fill: sand-brown, scale: 0.4),
  )
}

// ── Panel A ───────────────────────────────────────────────────────────────────
#let panel-a = canvas(length: 1.3cm, {
  import draw: *
  let s = (paint: dark-teal, thickness: 1.5pt)

  let a-rows = (
    ("0", "1", "1", "0", "0"),
    ("1", "0", "1", "0", "0"),
    ("1", "1", "0", "1", "0"),
    ("0", "0", "1", "0", "1"),
    ("0", "0", "0", "1", "0"),
  )
  let w-rows = (
    ("1", "0", "0"),
    ("1", "0", "0"),
    ("0", "1", "0"),
    ("0", "0", "1"),
    ("0", "0", "1"),
  )
  let w-row-colors = (olive, olive, bright, red, red)
  let y-rows = (
    ("1", "1", "0"),
    ("1", "1", "0"),
    ("2", "0", "1"),
    ("0", "1", "1"),
    ("0", "0", "1"),
  )
  let y-col-colors = (olive, bright, red)

  let eq-x = y-ox-l + yw + a-gap / 2
  let ti-x = a-ox-l + aw + a-gap / 2

  draw-matrix((y-ox-l, 0), y-rows, cw, ch, s, col-colors: y-col-colors)
  content((y-ox-l + yw / 2, mat-h + 0.4), text(size: 12pt)[Y (ARD counts)], anchor: "south")
  content((y-ox-l + yw / 2, -0.3), text(size: 12pt)[$NN^(n times k)$], anchor: "north")

  content((eq-x, mat-h / 2), text(size: 16pt)[$=$], anchor: "center")

  let s-grey = (paint: muted, thickness: 1.5pt)
  draw-matrix((a-ox-l, 0), a-rows, cw, ch, s-grey)
  content((a-ox-l + aw / 2, mat-h + 0.4), text(fill: muted, size: 12pt)[A (network)], anchor: "south")
  content((a-ox-l + aw / 2, -0.3), text(fill: muted, size: 12pt)[${0,1}^(n times n)$], anchor: "north")

  content((ti-x, mat-h / 2), text(size: 16pt)[$times$], anchor: "center")

  draw-matrix((w-ox-l, 0), w-rows, cw, ch, s, row-colors: w-row-colors)
  content((w-ox-l + ww / 2, mat-h + 0.4), text(size: 12pt)[W (traits)], anchor: "south")
  content((w-ox-l + ww / 2, -0.3), text(size: 12pt)[${0,1}^(n times k)$], anchor: "north")
})

// ── Panel A annotations ───────────────────────────────────────────────────────
#let anno-a-top = canvas(length: 1.3cm, {
  import draw: *
  anno(anno-a-top-cfg, text(fill: sand-brown, size: 14pt)[#align(center)[Which traits? How many?]])
})

#let anno-a-bottom = canvas(length: 1.3cm, {
  import draw: *
  content(
    anno-a-bottom-cfg.label-pos,
    text(fill: sand-brown, size: 14pt)[#align(center)[Traits must be binary and exclusive]],
    anchor: anno-a-bottom-cfg.label-anchor,
  )
})

#let panel-a-with-annots(show-top: false, show-bottom: false) = box(
  clip: false,
)[
  #panel-a
  #if show-top {
    place(top + left, dx: 120pt, dy: 176pt)[#anno-a-top]
  }
  #if show-bottom {
    place(top + left, dx: 92pt, dy: 200pt)[#anno-a-bottom]
  }
]

// ── Panel B: Latent space (Hoff model) ───────────────────────────────────────
#let ls-nodes = (
  (label: $v_1$, x: 1.3, y: 1.0, trait: 1, rx: 0.38, ry: 0.22, ldx: -0.65, ldy: 0.65, lanc: "south-west"),
  (label: $v_2$, x: 1.8, y: 2.0, trait: 1, rx: 0.30, ry: 0.18, ldx: -0.65, ldy: 0.65, lanc: "south-west"),
  (label: $v_3$, x: 4.2, y: 0.8, trait: 2, rx: 0.42, ry: 0.26, ldx: -0.65, ldy: 0.65, lanc: "south-west"),
  (label: $v_4$, x: 5.3, y: 2.8, trait: 3, rx: 0.34, ry: 0.20, ldx: -0.65, ldy: 0.65, lanc: "south-west"),
  (label: $v_5$, x: 5.9, y: 2.0, trait: 3, rx: 0.36, ry: 0.22, ldx: 0.30, ldy: -0.55, lanc: "north-west"),
)
#let ls-levels = (1.0, 1.6, 2.2)

#let panel-b = canvas(length: 1.2cm, {
  import draw: *
  let b-W = 7.0
  let b-H = 3.9

  for xi in range(0, 8) {
    line((xi, 0), (xi, b-H), stroke: (paint: muted, thickness: 0.4pt, dash: "dotted"))
  }
  for yi in range(0, 5) {
    line((0, yi), (b-W, yi), stroke: (paint: muted, thickness: 0.4pt, dash: "dotted"))
  }

  line(
    (0, 0),
    (b-W + 0.3, 0),
    stroke: (paint: dark-teal, thickness: 1.2pt),
    mark: (end: ">", scale: 0.5),
  )
  line(
    (0, 0),
    (0, b-H + 0.3),
    stroke: (paint: dark-teal, thickness: 1.2pt),
    mark: (end: ">", scale: 0.5),
  )

  let x-ticks = (
    (v: 0.0, lbl: $0$),
    (v: 1.75, lbl: $pi\/2$),
    (v: 3.5, lbl: $pi$),
    (v: 5.25, lbl: $3pi\/2$),
    (v: 7.0, lbl: $2pi$),
  )
  for tk in x-ticks {
    line((tk.v, 0), (tk.v, -0.12), stroke: (paint: dark-teal, thickness: 0.8pt))
    content((tk.v, -0.18), text(size: 12pt)[#tk.lbl], anchor: "north")
  }

  let y-ticks = (
    (v: 0.0, lbl: $0$),
    (v: 1.25, lbl: $pi\/4$),
    (v: 2.5, lbl: $pi\/2$),
    (v: 3.75, lbl: $3pi\/4$),
  )
  for tk in y-ticks {
    line((0, tk.v), (-0.12, tk.v), stroke: (paint: dark-teal, thickness: 0.8pt))
    content((-0.18, tk.v), text(size: 12pt)[#tk.lbl], anchor: "east")
  }

  content((b-W + 0.5, 0), text(size: 12pt, style: "italic")[$z_1$], anchor: "west")
  content((0, b-H + 0.5), text(size: 12pt, style: "italic")[$z_2$], anchor: "south")

  for nd in ls-nodes {
    let col = trait-color(nd.trait)
    let cx = nd.x
    let cy = nd.y
    for (li, lv) in ls-levels.enumerate() {
      let alpha = 100 - li * 28
      circle(
        (cx, cy),
        radius: (nd.rx * lv, nd.ry * lv),
        stroke: (paint: col.transparentize((100 - alpha) * 1%), thickness: 0.8pt, dash: "dashed"),
        fill: none,
      )
    }
    circle((cx, cy), radius: 0.10, fill: col, stroke: none)
    content(
      (cx + nd.ldx, cy + nd.ldy),
      text(fill: col, size: 12pt, weight: "bold")[#nd.label],
      anchor: nd.lanc,
    )
  }
})

// ── Panel C: Bootstrap network samples ───────────────────────────────────────
#let ns-nodes = (
  (x: 0.55, y: 0.9, trait: 1),
  (x: 1.05, y: 1.75, trait: 1),
  (x: 1.75, y: 0.25, trait: 2),
  (x: 2.55, y: 1.55, trait: 3),
  (x: 2.95, y: 0.75, trait: 3),
)
#let samples = (
  ((0, 1), (0, 2), (1, 2), (3, 4), (2, 3)),
  ((0, 1), (3, 4), (1, 2)),
  ((0, 1), (0, 2), (3, 4), (1, 3)),
)
#let sample-labels = ($A^((1))$, $A^((2))$, $A^((3))$)
#let sample-stats = ($t(A^((1))) = 5\/10$, $t(A^((2))) = 3\/10$, $t(A^((3))) = 4\/10$)

#let net-w = 3.5
#let net-gap = 1.2
#let node-r = 0.13
#let sample-offsets = (0.5, 4.7, 8.9)

#let panel-c = canvas(length: 1.0cm, {
  import draw: *
  let cedge = muted

  group({
    translate((0, -0.725))

    for (si, edges) in samples.enumerate() {
      let ox = sample-offsets.at(si)

      for (i, j) in edges {
        let ni = ns-nodes.at(i)
        let nj = ns-nodes.at(j)
        line(
          (ox + ni.x, ni.y),
          (ox + nj.x, nj.y),
          stroke: (paint: cedge, thickness: 0.9pt),
        )
      }
      for nd in ns-nodes {
        circle(
          (ox + nd.x, nd.y),
          radius: node-r,
          fill: trait-color(nd.trait),
          stroke: none,
        )
      }
      content(
        (ox + net-w / 2, -0.3),
        text(size: 12pt)[#sample-labels.at(si)],
        anchor: "north",
      )
      content(
        (ox + net-w / 2, -1.3),
        text(size: 12pt)[#sample-stats.at(si)],
        anchor: "north",
      )
    }
  })
})


// ── Panel D: Monte Carlo estimate ─────────────────────────────────────────────
#let panel-d = stack(
  dir: ttb,
  spacing: 5pt,
  canvas(length: 1cm, {
    import draw: *
    content((0, 0), text(size: 18pt)[$hat(EE)(t(A)) = 1/B sum_(b=1)^B t(A^(b))$], anchor: "center")
  }),
  v(0.5em),
  align(center)[#text(fill: muted, size: 13pt)[Ex: expected density]],
)

// ── Arrow helpers ─────────────────────────────────────────────────────────────
#let arrow-label(body) = text(size: 12pt, style: "italic")[#body]

#let right-arrow = canvas(length: 1pt, {
  import draw: *
  let carrow = dark-teal
  line((0, 0), (36, 0), stroke: (paint: carrow, thickness: 1.5pt), mark: (end: ">", fill: carrow, scale: 0.7))
})

#let left-arrow = canvas(length: 1pt, {
  import draw: *
  let carrow = dark-teal
  line((36, 0), (0, 0), stroke: (paint: carrow, thickness: 1.5pt), mark: (end: ">", fill: carrow, scale: 0.7))
})

// ── MCMC annotation ───────────────────────────────────────────────────────────
#let mcmc-anno-label = align(center)[
  #text(fill: sand-brown, size: 14pt, style: "italic")[Extremely slow]
]

#let mcmc-block(show-anno: false) = box(clip: false)[
  #stack(
    dir: ttb,
    spacing: 10pt,
    align(center)[#arrow-label[MCMC from\ Hoff model]],
    right-arrow,
  )
  #if show-anno {
    place(top + left, dx: 0pt, dy: -52pt)[
      #stack(dir: ttb, spacing: 4pt, mcmc-anno-label, canvas(length: 1pt, {
        import draw: *
        let carrow = sand-brown
        bezier(
          (15, 0),
          (10, -14),
          (4, -8),
          (0, -14),
          stroke: (paint: carrow, thickness: 0.8pt),
          mark: (end: ">", fill: carrow, scale: 0.4),
        )
      }))
    ]
  }
]

// ── Panel D annotation block ──────────────────────────────────────────────────
#let mc-anno-block(show-anno: false) = box(clip: false)[
  #panel-d
  #if show-anno {
    place(top + left, dx: -50pt, dy: 50pt)[
      #canvas(length: 1pt, {
        import draw: *
        content(
          (0, 0),
          text(
            fill: sand-brown,
            size: 14pt,
            style: "italic",
          )[Only useful if $t(A) arrow EE(t(A))$, or have data from many networks],
          anchor: "west",
        )
        bezier(
          (63, 16),
          (72, 30),
          (-18 + 70, 22),
          stroke: (paint: sand-brown, thickness: 0.8pt),
          mark: (end: ">", fill: sand-brown, scale: 0.4),
        )
      })
    ]
  }
]
