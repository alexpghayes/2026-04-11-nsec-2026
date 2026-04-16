#import "@preview/polylux:0.4.0": *
#import "@preview/cetz:0.3.4": canvas, draw
#import "theme.typ": *
#import "support-code.typ": *
#import "sigma_k_diagram.typ": *

#show: setup

// 22.5 minutes?
#slide[
  #set page(
    header: none,
    footer: none,
    margin: 3em,
  )

  #text(size: 1.3em)[
    Spectral Estimation and Trait Selection for Aggregated Relational Data
  ]

  #divider

  #set text(size: .8em, weight: "light")
  Alex Hayes

  April 11, 2026\
  Network Science in Economics 2026
]


#slide[
  = This is joint work with my postdoc mentor\* and  others

  #toolbox.side-by-side(gutter: 3mm)[
    #align(center)[
      #image("figures/arun.webp", height: 50%)

      Arun Chandrasekhar\* \
      #text(size: 0.8em)[Stanford Economics]
    ]
  ][
    #align(center)[
      #image("figures/tyler.jpg", height: 50%)

      Tyler McCormick \
      #text(size: 0.8em)[U. Washington Statistics]
    ]
  ][
    #align(center)[
      #image("figures/emily.jpg", height: 50%)

      Emily Breza \
      #text(size: 0.8em)[Harvard Economics]
    ]
  ]
]


#slide[
  = Roadmap for today

  + What is Aggregated Relational Data (ARD)?

  + Estimating low-rank models

  + Downstream plug-in inference

  + Practical guidance for designing ARD surveys
]

#new-section([What is Aggregated Relational Data (ARD)?])

#slide[
  = Studying networks often involves enormous experiments

  _Example 1_: Randomizing access to micro-credit amongst 75 villages in Karnataka, India, mapping out networks for 16,476 households @banerjee2024b

  #v(2em)

  #uncover(2)[
    _Example 2_: Randomizing whether information goes to an entire village or just a few seed households in each village, amongst 225 villages in Odisha, India @banerjee2024d
  ]
]

#slide[
  = Measuring social networks in person is very expensive

  #toolbox.side-by-side(gutter: 12mm, columns: (1fr, 1.5fr))[

    #set text(size: 13.5pt)

    #align(center)[
      #table(
        columns: (18em, 5em),
        align: (left, center),
        stroke: none,
        inset: 5pt,

        table.hline(stroke: 0.5pt),

        [_Panel A. Assumptions_], [],

        table.hline(stroke: 0.5pt),
        [Project duration (months)], [8.2],
        [Number of villages], [120],
        [Census sampling rate (percent)], [100],
        [Fully enumerated census], [Yes],
        [Sampling rate (percent)], [100 %],

        table.hline(stroke: 0.5pt),
      )
    ]
  ][

    #set text(size: 13.5pt)

    #align(center)[
      #table(
        columns: (15em, 8em, 10em),
        align: (left, right, right),
        stroke: none,
        inset: 5pt,

        [], [Total cost (\$)], [Per village cost (\$)],
        table.hline(stroke: 0.5pt),

        [_Panel B. Costs_], [], [],

        table.hline(stroke: 0.5pt),
        [Variable], [], [],
        [#h(1em)Census], [29,904], [249],
        [#h(1em)Networks survey], [84,954], [708],
        [#h(1em)Data entry and matching], [14,284], [119],
        [#h(1em)Tablet rentals], [8,584], [72],

        [Fixed], [], [],
        [#h(1em)Project staff salaries], [20,185], [168],
        [#h(1em)Travel], [1,617], [13],
        [#h(1em)J-PAL training/staff meetings], [1,916], [16],
        [#h(1em)Office expenses], [3,047], [25],

        [OH], [], [],
        [#h(1em)J-PAL IFMR OH (15 percent)], [24,674], [206],
        table.hline(stroke: 0.5pt),

        [Total cost], [_189,164_], [1,576],
        table.hline(stroke: 1pt),
      )
    ]
  ]

  #v(1em)
  #align(center)[#text(size: 18pt)[Typical costs estimated by J-PAL and reported in Table 4 of @breza2020]]
]


#slide[
  = One alternative is to collect _Aggregated Relational Data (ARD)_

  #toolbox.side-by-side(gutter: 5mm)[
    *Traditional surveys*
  ][
    *ARD surveys*
  ]
  #v(2em)


  #toolbox.side-by-side(gutter: 5mm)[

    #v(1em)

    - Who do you go to for advice?

    - Who do you visit?

    - Who lends kerosene or rice to you?
  ][
    How many people do you know who...

    - completed a college degree?

    - own a home?
  ]
]


#slide[
  = One alternative is to collect _Aggregated Relational Data (ARD)_

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
        let text-color = stroke-style.paint
        if row-colors != none {
          text-color = row-colors.at(i)
        } else if col-colors != none {
          text-color = col-colors.at(j)
        }

        let cx = ox + j * cell-w + cell-w / 2
        let cy = oy + (n-rows - 1 - i) * cell-h + cell-h / 2
        content((cx, cy), text(fill: text-color, size: 18pt, weight: "bold")[$#val$], anchor: "center")
      }
    }
  }

  #align(center + horizon)[
    #canvas(length: 1.8cm, {
      // Reduced length to prevent spilling
      import draw: *

      let s = (paint: dark-teal, thickness: 1.8pt)
      let s-grey = (paint: muted, thickness: 1.8pt)

      let cw = 1.1
      let ch = 1.1
      let gap = 1.2

      // Data
      let a-rows = (
        ("0", "1", "1", "0", "0"),
        ("1", "0", "1", "0", "0"),
        ("1", "1", "0", "1", "0"),
        ("0", "0", "1", "0", "1"),
        ("0", "0", "0", "1", "0"),
      )
      let w-rows = (("1", "0", "0"), ("1", "0", "0"), ("0", "1", "0"), ("0", "0", "1"), ("0", "0", "1"))
      let y-rows = (("1", "1", "0"), ("1", "1", "0"), ("2", "0", "1"), ("0", "1", "1"), ("0", "0", "1"))

      // Colors
      let y-col-colors = (olive, bright, red)
      let w-row-colors = (olive, olive, bright, red, red)

      let yw = 3 * cw
      let aw = 5 * cw
      let ww = 3 * cw
      let mat-h = 5 * ch

      let y-ox = 0.0
      let a-ox = y-ox + yw + gap
      let w-ox = a-ox + aw + gap

      // ── Y matrix
      draw-matrix((y-ox, 0), y-rows, cw, ch, s, col-colors: y-col-colors)
      content((y-ox + yw / 2, mat-h + 0.5), text(fill: dark-teal, size: 22pt)[Y (ARD counts)], anchor: "south")
      content((y-ox + yw / 2, -0.4), text(fill: dark-teal, size: 22pt)[$NN^(n times k)$], anchor: "north")

      content((y-ox + yw + gap / 2, mat-h / 2), text(fill: dark-teal, size: 24pt)[$=$])

      // ── A matrix (muted matrix, Black labels)
      draw-matrix((a-ox, 0), a-rows, cw, ch, s-grey)
      content((a-ox + aw / 2, mat-h + 0.5), text(fill: dark-teal, size: 22pt)[A (network)], anchor: "south")
      content((a-ox + aw / 2, -0.4), text(fill: dark-teal, size: 22pt)[${0, 1}^(n times n)$], anchor: "north")

      content((a-ox + aw + gap / 2, mat-h / 2), text(fill: dark-teal, size: 24pt)[$times$])

      // ── W matrix
      draw-matrix((w-ox, 0), w-rows, cw, ch, s, row-colors: w-row-colors)
      content((w-ox + ww / 2, mat-h + 0.5), text(fill: dark-teal, size: 22pt)[W (traits)], anchor: "south")
      content((w-ox + ww / 2, -0.4), text(fill: dark-teal, size: 22pt)[${0, 1}^(n times k)$], anchor: "north")
    })
  ]
]

#slide[
  = ARD is _much cheaper_ to collect and _preserves privacy_

  #align(center)[

    #set text(size: 14pt)

    #table(
      columns: (15em, 8em, 10em, 8em, 10em),
      align: (left, right, right, right, right),
      stroke: none,
      inset: 5pt,

      [],
      table.cell(colspan: 2, align: center)[Traditional network survey],
      table.cell(colspan: 2, align: center)[ARD survey],
      [], [Total cost (\$)], [Per village cost (\$)], [Total cost (\$)], [Per village cost (\$)],
      table.hline(stroke: 0.5pt),

      [_Panel B. Costs_], [], [], [], [],
      [Variable], [], [], [], [],
      [#h(1em)Census], [29,904], [249], [12,816], [107],
      [#h(1em)Networks survey], [84,954], [708], [4,486], [37],
      [#h(1em)Data entry and matching], [14,284], [119], [], [0],
      [#h(1em)Tablet rentals], [8,584], [72], [1,026], [9],

      [Fixed], [], [], [], [],
      [#h(1em)Project staff salaries], [20,185], [168], [7,959], [66],
      [#h(1em)Travel], [1,617], [13], [638], [5],
      [#h(1em)J-PAL training/staff meetings], [1,916], [16], [1,886], [16],
      [#h(1em)Office expenses], [3,047], [25], [1,201], [10],

      [OH], [], [], [], [],
      [#h(1em)J-PAL IFMR OH (15 percent)], [24,674], [206], [4,502], [38],
      table.hline(stroke: 0.5pt),

      [Total cost], [_189,164_], [1,576], [_34,512_], [288],
      table.hline(stroke: 1pt),
    )
  ]

  #v(1em)
  #align(center)[#text(size: 13.5pt)[Costs estimated by J-PAL and reported in Table 4 of @breza2020]]
]

// #new-section([Challenges working with Aggregated Relational Data])

// #slide[
//   = Extant methods to analyze ARD are limited in important ways
//   #pad(x: -0.5em, y: -0.5em)[
//     #grid(
//       columns: (1fr, 64pt, 1fr),
//       rows: (1fr, 64pt, 1fr),
//       gutter: 0pt,
//       // ── Panel row 1 ──────────────────────────────────────────────────────
//       align(center + horizon)[
//         #only(1)[#panel-a-with-annots(show-top: false, show-bottom: false)]
//         #only(2)[#panel-a-with-annots(show-top: true, show-bottom: false)]
//         #only((3, 4, 5, 6, 7, 8))[#panel-a-with-annots(show-top: true, show-bottom: true)]
//       ],
//       align(center + horizon)[
//         #only(4)[#mcmc-block(show-anno: false)]
//         #only((5, 6, 7, 8))[#mcmc-block(show-anno: true)]
//       ],
//       align(center + horizon)[
//         #only((4, 5, 6, 7, 8))[#panel-b]
//       ],
//       // ── Arrow row ────────────────────────────────────────────────────────
//       [],
//       [],
//       align(center + horizon)[
//         #only((6, 7, 8))[
//           #stack(
//             dir: ltr,
//             spacing: 6pt,
//             canvas(length: 1pt, {
//               import draw: *
//               let carrow = dark-teal
//               line(
//                 (0, 0),
//                 (0, -36),
//                 stroke: (paint: carrow, thickness: 1.5pt),
//                 mark: (end: ">", fill: carrow, scale: 0.7),
//               )
//             }),
//             align(left + horizon)[#arrow-label[Bootstrap\ networks]],
//           )
//         ]
//       ],
//       // ── Panel row 2 ──────────────────────────────────────────────────────
//       align(center + horizon)[
//         #only(7)[#mc-anno-block(show-anno: false)]
//         #only(8)[#mc-anno-block(show-anno: true)]
//       ],
//       align(center + horizon)[
//         #only((7, 8))[
//           #stack(dir: ttb, spacing: 10pt, left-arrow, align(center)[#arrow-label[Monte Carlo estimation]])
//         ]
//       ],
//       align(center + horizon)[
//         #only((6, 7, 8))[#panel-c]
//       ],
//     )
//   ]
// ]

#slide[
  = We propose a two-stage estimation procedure

  #toolbox.side-by-side(gutter: 0mm)[
    #align(center)[
      *1. Estimate low-rank model*
    ]
  ][
    #align(center)[
      *2. Downstream plug-in inference*
    ]
  ]

  #toolbox.side-by-side(gutter: 0mm)[
    #align(center)[
      #image("figures/blockmodel-phat.png")
    ]
  ][
    #align(center)[
      #image("figures/blockmodel-lim.png")
    ]
  ]
]

#new-section([Estimating low-rank models])

#slide[
  = Intuition for the network model: stochastic blockmodels <sbm-intuition>

  #toolbox.side-by-side(gutter: 5mm)[
    #align(center + horizon)[
      #figure(
        image("figures/blockmodel.png"),
      )
    ]
  ][
    #align(horizon)[
      Block indicators $Z_i$ \
      Popularity parameters $gamma_i$ \
      Mixing matrix $B in [0, 1]^(k times k)$
      #v(1em)
      $PP(A_(i j) = 1 | Z, gamma, B) = gamma_i Z_i B Z_j^top gamma_j$
      #v(1em)
      $A_(i j) "i.i.d."$ conditional on $Z, gamma, B$

      // #show link: button
      // #link(<appendix:sbm>)[SBM microfoundation]
    ]
  ]
]

#slide[
  = Low-rank network models vastly generalize blockmodels

  #toolbox.side-by-side(gutter: 5mm)[
    #align(center + horizon)[
      #figure(
        image("figures/blockmodel.png"),
      )
    ]
  ][
    #v(0.75em)
    #align(horizon)[
      $PP(A_(i j) = 1 mid(|) U, S) = underbrace(U S U^top, "rank" k "svd")$
    ]
    #v(0.75em)
    $A_(i j) "i.i.d."$ conditional on $U, S$
    #v(0.75em)
    E.g., could include:
    - Degree-correction
    - Mixed membership
    - Overlapping membership
    - Etc, etc, etc
  ]
]


#slide[
  = We want to estimate parameters of low-rank networks
  *Data*
  $
          A & in {0, 1}^(n times n) quad quad && "network adjacency matrix" quad quad && #text(bright)[unknown] \
          W & in RR^(n times k) quad quad     && "traits matrix (fixed)" quad quad    && "observed" \
    Y = A W & in RR^(n times k) quad quad     && "ARD count matrix" quad quad         && "observed"
  $
  #v(1em)
  *Low-rank network assumption*
  #v(1em)
  $EE(A mid(|) U, S) = U S U^top$ is rank $k$, p.s.d. for notational convenience

  _Goal_: estimate population eigenvectors $U$ and eigenvalues $S$
]

#focus[
  _$"col"(Y) = "col"(A W) subset.eq "col"(A)$_
  #v(1em)
  Provided $W$ doesn't intersect $"null"(A)$, $"col"(Y) = "col(A)" approx^* "col"(U)$
  #v(1em)
  #text(fill: muted, size: 0.8em)[\*since $A$ concentrates around $EE(A) = U S U^top$]
]

#slide[
  = The column space argument yields an identification result
  Moving to the population
  $
    EE(Y mid(|) U, S) & = EE(A mid(|) U, S) space W \
    & = U underbrace(S U^top space U_W S_W, "take svd") V_W^top \
    & = (U Q_U) S_B (V_W Q_V)^top && quad quad quad quad "SVD of " EE(Y mid(|) U, S)
  $
  #v(1.5em)
  where $B = Q_U space S_B space Q_V^top$ is full rank $k$ SVD of $S space U^top space U_W space S_W$
  #v(1em)
  But $S_B$ might not be full rank = rank $k$!
]

#slide[
  = Intuitive assumptions are needed for identification

  To ensure that $EE(Y mid(|) U, S)$ has $k$ non-zero singular values, assume:

  + Low rank network structure. $EE(A mid(|) U, S) = rho_n U S U^top$ with rank $k$

  + Sufficient number of traits. The trait matrix $W in RR^(n times k)$ has rank $k$.

  + Traits explain latent variation in all directions. $0 lt sigma_k (U^top U_W)$ where $sigma_k (M)$ denotes the $k$th singular value of $M$.

  #v(2em)
  Identification follows from a multiplicative variant of Weyl's inequality

  $
    0 < sigma_k (S) space sigma_k (S_W) space sigma_k (U^top U_W) <= sigma_k (S_B) = sigma_k (EE(Y mid(|) U, S))
  $
]

#slide[
  = What does the identifying assumption #text(fill: bright)[$sigma_k (U^top U_W) > 0$] mean? <interpreting-sigmak>

  #grid(
    columns: (1fr, 1.2fr),
    gutter: 1em,
    [
      #align(center)[
        #sigma-diagram
      ]

      #text(size: 18pt)[
        $sigma_k (U^top U_W) = cos theta_k in [0, 1]$
        #v(0.5em)
        $sigma_k (U^top U_W) = 0$ means $exists u in U$ s.t. $u perp W$
        $sigma_k (U^top U_W) = 1$ means $"col"(U) = "col"(W)$
      ]

      #show link: button
      #align(center)[#link(<survey-design>)[Implications for survey design]]
    ],
    [
      *Geometrically*: the cosine of the _smallest_ #link(<appendix:principal-angles>)[principal angle] $theta_k$ between $"col"(U)$ and $"col"(U_W)$ > 0
      #v(0.75em)
      *Stochastic blockmodel*: the canonical correlation between $W$ and the block it is _least_ correlated with > 0
      #v(0.75em)
      *Statistically*: $W$ explains at least a non-zero fraction of variance in each column of population eigenvectors $U$
    ],
  )
]

#slide[
  = Uniform bounds for estimating population singular vectors $U$

  Let $tilde(U) tilde(S) tilde(V)^top$ be the rank $k$ SVD of $Y in RR^(n times k)$. If, additionally,

  + the average degree $n rho_n$ is growing ($n rho_n$ is $Omega(log n)$),

  + the traits $W$ are independent of $A$ conditional on $U$ and $S$, and

  + the traits are well-conditioned ($kappa(W)$ is $cal(O)(1)$),

  then, with probability $1 - cal(O)(n^(-2))$ there exists an orthogonal matrix $Q$ such that
  $
    norm(tilde(U) - U Q)_(2 arrow oo)
    lt.eq (C log n) / (#text(fill: bright)[$sigma_k (U^top U_W)$] space n rho_n)
  $
]

#slide[
  = Estimating the population eigenvalues $S$ is more involved
  Under our identifying assumptions, we can solve for $S$
  $
            U S U^top W & = EE(Y) \
    U S U^top W W^top U & = EE(Y) W^top U \
                    U S & = EE(Y) W^top U (U^top W W^top U)^(-1)       && quad "since" sigma_k (U^top U_W) > 0 \
                      S & = U^top EE(Y) W^top U (U^top W W^top U)^(-1) \
  $
]

#slide[
  = Finding $S$ in terms of $U, W, EE(Y)$ suggests plug-in estimation
  We propose the estimator
  $
    tilde(Sigma) = tilde(U)^top Y W^top tilde(U) (tilde(U)^top W W^top tilde(U))^(-1)
  $
  Under the same assumptions as before, with probability $1 - cal(O)(n^(-2))$ and taking the same orthogonal $Q$ as before,
  $
    norm(tilde(Sigma) - Q^top S Q) = cal(O) (log(n) / #text(fill: bright)[$sigma_k (U^top U_W)$])
  $
]

#slide[
  = Recovering $P = EE(A | U, S)$ and $X = U S^(1\/2)$ are corollaries
  In same setting, with probability $1 - cal(O)(n^(-2))$ and orthogonal $Q$
  $
    tilde(P) = tilde(U) tilde(Sigma) tilde(U)^top quad "and" quad tilde(X) = tilde(U) tilde(Sigma)^(1\/2)
  $
  again matches rates for known $A$, but scaled by constant term
  $
    norm(tilde(P) - P) = cal(O) (sqrt(n rho_n) / #text(fill: bright)[$sigma_k (U^top U_W)$]) \
    norm(tilde(X) - X Q)_(2 -> oo) = cal(O) (log(n) / (sqrt(n rho_n) space #text(fill: bright)[$sigma_k (U^top U_W)$]))
  $
  #align(center)[
    Why $P = EE(A | U, S)$? Link presence! Why $X = U S^(1\/2)$? Constant scale!
  ]
]


#slide[
  = Our spectral estimators are easier to use than past estimators

  #cite(<mccormick2015>, form: "author") propose an MCMC sampler under a Hoff model

  #v(1em)
  #toolbox.side-by-side(gutter: 5mm)[
    === MCMC Estimator
  ][
    === Spectral Estimator
  ]

  #v(1em)

  #toolbox.side-by-side(gutter: 5mm)[

    - MCMC takes _several days on a cluster_ on #cite(<breza2023a>, form: "prose") data

    - Traits must be _binary_

    - Traits must be _mutually exclusive_

    - Need _many networks_
  ][
    - SVD takes _15 seconds on a laptop_ on #cite(<breza2023a>, form: "prose") data

    - Traits can be _real-valued_

    - Traits _allowed to overlap_

    - Only need a _single network_
  ]
]

#slide[
  = Our estimators match rates when the network is known

  When $A$ is known, rank $k$ SVD of $A approx hat(U) hat(S) hat(V)^top$ is canonical. We match rates of this estimator, but scaled by the constant factor #text(fill: bright)[$sigma_k (U^top U_W)$]

  Rates when $A$ is known:
  $
    norm(hat(U) - U Q)_(2 arrow oo) & = cal(O) ( log(n) / (n rho_n)) quad quad quad
                                      norm(hat(S) - Q^top S Q)     && = cal(O) (log(n)) \
                   norm(hat(P) - P) & = cal(O) (sqrt(n rho_n)) quad quad quad
                                      norm(hat(X) - X Q)_(2 -> oo) && = cal(O) (log(n) / sqrt(n rho_n))
  $

  The dominant error term for ARD estimates is _also linear in $A - P$_, so ARD estimates and canonical estimates have _similar structure_
]

#new-section([Downstream plug-in inference])

#slide[
  = What downstream inference is possible with $tilde(U)$ and $tilde(S)$?

  *We prove*:

  + A functional law of large numbers for $tilde(U)$ and $tilde(S)$

  + $tilde(U)$ and $tilde(S)$ can be used to estimate linear-in-means models

  #v(1em)
  *We strongly suspect*:
  #v(1em)
  #align(center)[
    Most RDPG tools for the $A$ known case should work with $tilde(U)$ and $tilde(S)$
  ]
  #text(
    fill: muted,
  )[...since our estimates (1) match rates for the $A$ known case and (2) have a similar error structure]
]

#slide[
  = $tilde(U)$ and $tilde(S)$ obey a functional law of large numbers

  Recall $tilde(X) = tilde(U) tilde(S)^(1\/2)$. For $f$ with bounded bracketing integral, twice continuously differentiable in $X$, additional nodal data $O_i$

  $
    sup_(f in cal(F)) lr(|1 / sqrt(n) sum_(i=1)^n f(tilde(X)_i Q, O_i) - f(X_i, O_i)|) = o_p (1)
  $
  under envelope conditions on the gradient of $f$
]

#slide[
  = Estimating peer effects with Aggregated Relational Data

  Suppose we want to estimate
  $
    Y = 1 beta_0 + G Y beta_(g y) + W beta_w + G W beta_(g w) + epsilon
  $
  where $G = D^(-1) A$ is the row-normalized adjacency matrix.

  We don't know _$A$_!

  Idea: plug-in $tilde(P)$ for $A$ in the canonical two-stage least squares estimator
]


#slide[
  = We propose a plug-in estimator for peer effects
  $
    tilde(beta) = (tilde(Z)^top tilde(M) tilde(Z))^(-1) tilde(Z)^top tilde(M) Y
  $
  where
  $ tilde(Z) = [1 space W space tilde(G) W space tilde(G) Y] quad quad quad quad tilde(G) = D^(-1) tilde(P) $ is the covariate matrix and
  $ tilde(M) = tilde(H) (tilde(H)^top tilde(H))^(-1) tilde(H)^top $ is the projection onto the span of the instrument matrix
  $ tilde(H) = [W space tilde(G) W space tilde(G)^2 W space tilde(G)^3 W] $
]


#slide[
  = The plug-in estimator is equivalent to the canonical estimator
  If

  + the assumptions for the canonical two-stage least squares estimator $beta^*$ hold, such that $sqrt(n) (beta^* - beta) -> cal(N)(0, Sigma)$,

  + the assumptions to estimate $U$ and $S$ via ARD hold, and

  + the average degree $n rho_n$ grows at $omega(sqrt(n) log n)$ rate,

  then, $tilde(beta)$ is asymptotically as good an estimator as $beta^*$
  $
    sqrt(n) (tilde(beta) - beta) -> cal(N)(0, Sigma)
  $
]


#slide[
  = We provide uncertainty quantification in downstream analysis

  *Past work*:

  - #cite(<breza2023a>, form: "prose"): consistent estimates of "stable" statistics

  - #cite(<breza2020>, form: "prose"): regression on *expected* network statistics

  - #cite(<ward2025a>, form: "prose"): credible inverals for sub-population sizes

  #v(1em)
  *This work*:

  - Full uncertainty quantification accounting for estimation of network parameters

]


#slide[
  = There are many other tools for inference in low-rank networks

  Clustering @lyzinski2014 @lyzinski2017

  Network regression @hayes2025

  Network association testing, CCA, LASSO @fuchs-kreiss2025

  Comparisons of multiple networks @tang2017

  Bootstrapping @levin2025

  Out-of-sample embedding @levin2021

  #v(1em)
  #align(center)[Useful survey: #cite(<athreya2018>, form: "prose")]
]


#new-section([Practical guidance for designing ARD surveys])

#slide[
  #show: focus

  Current advice on designing ARD surveys:

  "Ask 5-8 ARD questions"

  #v(1em)

  This is where _people get stuck_
]


#slide[
  = Designing ARD surveys using only domain knowledge <survey-design>

  #show link: button
  Want $W$ that maximizes #text(fill: bright)[$sigma_k (U^top U_W)$]

  - Choose traits that explain as much homophily in the network as possible

  - Having too many traits is fine (but possibly expensive)

  - Traits must explain variation in every dimension of latent node embeddings (predict membership in all blocks in a blockmodel)

  - You need some estimate of the number of groups in your network $k$, and you must have at least $k$ linearly independent traits.

  - Avoid collinear and rare traits

  #align(right)[#link(<interpreting-sigmak>)[Interpreting $sigma_k (U^top U_W)$]]
]

#slide[
  = Example of good and bad traits when full network is known
  #toolbox.side-by-side(gutter: 1mm)[
    #align(center)[
      #image("figures/karnataka-village-5.png", height: 85%)
      Karnataka Village 5
    ]
  ][
    Informative traits

    - Caste
    - Sub-caste (see left figure)
    - Home owned vs rented
    - Occupation
    - Type of roof on home
    - Number of rooms in home

    Uninformative traits

    - Sex
    - Presence of electricity in home
  ]
]

#slide[
  = Simulations suggest robustness to some uninformative traits

  #align(center)[
    #image("figures/sin-theta.png")
  ]
]

#slide[
  = Takeaways

  Network data is useful but expensive, ARD is cheaper

  We proposed a way to estimate RDPG parameters with ARD

  We fully quantify uncertainty due to ARD in downstream inference

  We offer concrete advice on traits to survey
]

#slide[

  = Thank you! Questions? Comments?

  #toolbox.side-by-side(gutter: 5mm, columns: (1.3fr, 1fr))[

    Network data is expensive, ARD is cheap

    Two stage spectral estimation is convenient and enables full uncertainty quantification in downstream analysis

    Good traits are strongly homophilous

    #v(1em)
    #set list(marker: none)

    #align(left)[

      #set text(size: 0.8em)

      #list(
        [#box(image("figures/icons/bluesky.svg", height: 1em, fit: "contain"), baseline: 5pt) #h(0.5em) #link(
            "https://bsky.app/profile/alexpghayes.com",
          )[\@alexpghayes.com]],
        [#box(image("figures/icons/envelope.svg", height: 1em, fit: "contain"), baseline: 5pt) #h(0.5em) #link(
            "mailto:alexpgh@stanford.edu",
          )[alexpgh\@stanford.edu]],
        [#box(image("figures/icons/wordpress.svg", height: 1em, fit: "contain"), baseline: 5pt) #h(0.5em) #link(
            "https://www.alexpghayes.com",
          )[alexpghayes.com]],
        [#box(image("figures/icons/github.svg", height: 1em, fit: "contain"), baseline: 5pt) #h(0.5em) #link(
            "https://github.com/alexpghayes",
          )[github.com/alexpghayes]],
      )
    ]
  ][
    #image("figures/sin-theta-last-slide.png")
  ]

  // #align(center)[
  //   #text(muted, size: 0.8em)[These slides are available at github.com/alexpghayes/2025-11-14-madison-networks]
  // ]
]

#new-section([Appendix])

// #slide[
//   = Microfoundations for low-rank network models

//   Actor $i$ chooses tie probability $p_(i j) in [0, 1]$ to maximize expected complementarity minus a quadratic effort cost:
//   $ U_i (p_(i j)) = p_(i j) (x_i^T x_j) - 1/(2 rho_n) p_(i j)^2 $
//   where $x_i, x_j in bb(R)^k$ are latent positions and $1/rho_n > 0$ is the universal friction.

//   $ (partial U_i) / (partial p_(i j)) = x_i^T x_j - 1/rho_n p_(i j) = 0 quad => quad p_(i j)^* = rho_n x_i^T x_j $

//   #show link: button
//   #align(right)[#link(<sbm-intuition>)[Back to SBM intuition]]
// ]

#slide[
  = Principal angles between subspaces <appendix:principal-angles>

  Let $cal(U)$ and $cal(V)$ be two $k$-dimensional subspaces of $RR^n$. The principal angles $theta_1, ..., theta_k$ between $cal(U)$ and $cal(V)$ are given by

  $
    theta_1 & = min {arccos((u^top v) / (norm(u) norm(v))) mid(|) u in cal(U), v in cal(V)}
  $
  denote the minimizers $u_1$ and $v_1$.

  $
    theta_i & = min {arccos((u^top v) / (norm(u) norm(v))) mid(|) u in cal(U), v in cal(V), u perp u_j, v perp v_j space forall j in {1, ..., i - 1}}
  $

  #show link: button
  #align(right)[#link(<interpreting-sigmak>)[Back to Interpreting #text(fill: bright)[$sigma_k (U^top U_W) > 0$]]]
]


#slide[
  = The canonical two-stage least stages linear-in-means estimator
  $
    beta^* = (Z^top M Z)^(-1) Z^top M Y
  $
  where
  $
    Z = [1 space W space G W space G Y] quad quad quad quad G = D^(-1) A
  $
  is the covariate matrix and
  $
    M = H (H^top H)^(-1) H^top
  $
  is the projection onto the span of the instrument matrix
  $
    H = [W space G W space G^2 W space G^3 W].
  $
]

#slide[
  = Assumptions of the canonical two-stage least squares estimator

  + All diagonal elements of $G$ are zero

  + $(I - beta_(g y) G)^(-1)$ is non-singular with $lr(|beta_(g y)|) < 1$.

  + $G$ and $I - beta_(g y) G$ are uniformly bounded in row and column sums.

  + The regressor matrices $W$ have full column rank (for $n$ large enough), and the elements of $W$ are uniformly bounded in absolute value.

  + $epsilon$ are i.i.d. with zero mean and bounded variance $bb(E)[epsilon_i^2] = sigma_epsilon^2 < b < infinity$. Additionally $epsilon_i$ have finite fourth order moments.
]


#slide[
  = Assumptions of the canonical two-stage least squares estimator

  Further, the instruments $H$ have full column rank and are composed of a subset of linearly independent columns of $mat(W, G W, G^2 W)$ where the subset contains $W$ and $X$. Additionally
  $
    lim_(n -> oo) 1/n H^top H
  $
  is finite and non-singular and
  $
    1/n H^top Z
  $
  converges in probability to a matrix that is finite and has full column rank.
]

#slide[
  = Assumptions of the canonical two-stage least squares estimator

  If all the previous assumptions hold, then
  $
    sqrt(n) (beta^* - beta) -> cal(N)(0, sigma_epsilon^2 (Z^top M Z)^(-1))
  $
  recalling that
  $
    Z = [1 space W space G W space G Y] quad quad quad quad G = D^(-1) A
  $
  is the covariate matrix and
  $
    M = H (H^top H)^(-1) H^top
  $
  is the projection onto the instruments $H = [W space G W space G^2 W space G^3 W]$.
]

#slide[
  #bibliography("ard-trait-selection.bib", style: "apa")
]
