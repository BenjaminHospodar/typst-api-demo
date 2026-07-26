#set page(paper: "a4", margin: (x: 2cm, y: 2cm))
#set text(size: 10pt)
#set par(justify: true)

// ── Dashboard-style template with computed layouts ──────────
#align(center)[
  #text(22pt, weight: "bold")[#vars.name]
  #v(0.3em)
  #text(11pt, fill: gray)[Analytics Dashboard — #vars.date]
]

#v(1em)

// ── KPI Cards row ───────────────────────────────────────────
#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 12pt,
  ..{
    let cards = (
      ("Users", "12,847", "+14%", green),
      ("Revenue", "\$89.2k", "+8%", blue),
      ("Orders", "3,421", "+22%", purple),
      ("Churn", "2.1%", "-0.3%", red),
    )
    cards.map(card => {
      box(
        width: 100%,
        inset: 12pt,
        radius: 6pt,
        fill: card.at(3).lighten(90%),
        stroke: card.at(3).lighten(60%),
        [
          #text(9pt, fill: gray)[#card.at(0)]
          #v(4pt)
          #text(18pt, weight: "bold")[#card.at(1)]
          #v(2pt)
          #text(10pt, fill: card.at(3))[#card.at(2)]
        ]
      )
    })
  }
)

#v(1.5em)

// ── Large data table ────────────────────────────────────────
== Top Products

#table(
  columns: (auto, 2fr, 1fr, 1fr, 1fr, 1fr),
  inset: 7pt,
  fill: (col, row) => if row == 0 { rgb("#1e293b") } else if calc.rem(row, 2) == 0 { rgb("#f1f5f9") },
  table.header(
    text(fill: white)[*\#*],
    text(fill: white)[*Product*],
    text(fill: white)[*Units*],
    text(fill: white)[*Revenue*],
    text(fill: white)[*Growth*],
    text(fill: white)[*Margin*],
  ),
  [1], [Enterprise Plan], [1,204], [\$45,200], [+18%], [72%],
  [2], [Pro Plan], [2,847], [\$28,470], [+12%], [68%],
  [3], [Starter Plan], [5,102], [\$10,204], [+25%], [82%],
  [4], [Add-on: Storage], [3,891], [\$3,891], [+31%], [91%],
  [5], [Add-on: API], [1,502], [\$7,510], [+9%], [88%],
  [6], [Consulting Hours], [340], [\$17,000], [-5%], [45%],
  [7], [Training Packages], [89], [\$4,450], [+42%], [78%],
  [8], [Custom Integration], [23], [\$11,500], [+15%], [52%],
)

#v(1.5em)

// ── Two-column insights ─────────────────────────────────────
#columns(2)[
  == Trends
  #vars.at("text1", default: "User acquisition increased 14% month-over-month, driven primarily by organic search improvements and the new referral program launched in March.")

  Key drivers:
  + Organic search traffic up 23%
  + Referral program contributing 18% of new signups
  + Social media campaigns reached 2.1M impressions
  + Email nurture sequences improved conversion by 8%

  #colbreak()

  == Action Items
  + Scale infrastructure for projected 50% traffic increase
  + Launch enterprise tier pricing revision
  + Complete SOC 2 Type II certification
  + Hire 3 additional engineers for platform team
  + Migrate legacy customers to new billing system

  #v(0.5em)
  #vars.at("text3", default: "Next review scheduled for end of quarter.")
]

// ── Footer ──────────────────────────────────────────────────
#v(2em)
#line(length: 100%, stroke: 0.5pt + gray)
#v(0.5em)
#text(8pt, fill: gray)[
  #vars.name · Generated #vars.date · Page #counter(page).display() of #locate(loc => counter(page).final(loc).first())
]
