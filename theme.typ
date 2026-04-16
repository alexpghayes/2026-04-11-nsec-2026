#import "@preview/polylux:0.4.0": *

#let olive = rgb("#84994F")
#let yellow = rgb("#FFE797")
#let red = rgb("#A72703")
#let dark-teal = rgb("#365257")

#let bright = rgb("#eb811b")
#let brighter = rgb("#d6c6b7")
#let muted = rgb("#bbbbbb")
#let sand-brown = rgb("#8a6a3a")


#let slide-title-header = toolbox.next-heading(h => {
  show: toolbox.full-width-block.with(fill: text.fill, inset: 1em)
  set align(horizon)
  set text(fill: page.fill, size: 1.2em)
  h
})

#let progress-bar = toolbox.progress-ratio(ratio => {
  set grid.cell(inset: (y: .03em))
  grid(
    columns: (ratio * 100%, 1fr),
    grid.cell(fill: bright)[],
    grid.cell(fill: brighter)[],
  )
})

#let new-section(name) = slide({
  set page(header: none, footer: none)
  show: pad.with(20%)
  set text(size: 1.5em)
  name
  toolbox.register-section(name)
  progress-bar
})

#let focus(body) = context {
  set page(header: none, footer: none, fill: text.fill, margin: 2em)
  set text(fill: page.fill, size: 1.5em)
  set align(center)
  body
}

#let divider = line(length: 100%, stroke: .1em + bright)

#let button(it) = box(
  fill: dark-teal,
  inset: (x: 0.6em, y: 0.3em),
  radius: 0.2em,
  text(fill: white, size: 0.7em, it),
)

#let setup(
  footer: none,
  text-font: "Charter",
  math-font: "TeX Gyre Schola Math",
  code-font: "Fira Code",
  text-size: 24pt,
  body,
) = {
  set page(
    paper: "presentation-16-9",
    fill: white.darken(2%),
    margin: (top: 3em, rest: 1em),
    footer: none,
    header: slide-title-header,
  )
  set text(
    font: text-font,
    // weight: "light", // looks nice but does not match Fira Math
    size: text-size,
    fill: dark-teal, // dark teal
  )
  // set strong(delta: 100)
  show math.equation: set text(font: math-font)
  show raw: set text(font: code-font)
  set align(horizon)
  show emph: it => text(fill: bright, it.body)
  show heading.where(level: 1): _ => none

  set enum(
    indent: 1em,
    numbering: "1.a.i.",
  )


  body
}

