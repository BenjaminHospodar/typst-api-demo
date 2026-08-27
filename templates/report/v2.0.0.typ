#let vars = json.decode(sys.inputs.at("data", default: "{}"))

#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm))
#set text(size: 10pt)
#set par(justify: true)

// ── Header ──────────────────────────────────────────────────
#align(center)[
  #text(24pt, weight: "bold")[#vars.name]
  #v(0.5em)
  #text(14pt, fill: gray)[Quarterly Financial Report — #vars.date]
]

#line(length: 100%)
#v(1em)

// ── Summary Table ───────────────────────────────────────────
#table(
  columns: (1fr, 1fr, 1fr, 1fr),
  inset: 8pt,
  align: center,
  fill: (col, row) => if row == 0 { rgb("#2563eb").lighten(80%) } else if calc.rem(row, 2) == 0 { rgb("#f3f4f6") },
  [*Quarter*], [*Revenue*], [*Expenses*], [*Profit*],
  [Q1], [\$120,000], [\$85,000], [\$35,000],
  [Q2], [\$145,000], [\$92,000], [\$53,000],
  [Q3], [\$138,000], [\$88,000], [\$50,000],
  [Q4], [\$167,000], [\$95,000], [\$72,000],
  [*Total*], [*\$570,000*], [*\$360,000*], [*\$210,000*],
)

#v(1em)

// ── Multi-column layout ─────────────────────────────────────
#columns(2)[
  == Executive Summary
  #vars.at("text1", default: "This report provides a comprehensive overview of the company's financial performance across all four quarters of the fiscal year.")

  #v(0.5em)

  The company showed consistent growth with a total revenue increase of 39% from Q1 to Q4. Operating margins improved from 29% to 43%, demonstrating improved operational efficiency.

  #colbreak()

  == Key Highlights
  - Revenue grew 39% year-over-year
  - Operating margin improved to 43%
  - Customer acquisition cost decreased by 15%
  - Employee headcount grew by 22%

  #v(0.5em)

  == Outlook
  #vars.at("text3", default: "Management expects continued growth in the next fiscal year with projected revenue of \$750,000.")
]

#v(1em)
#line(length: 100%)

// ── Nested tables ───────────────────────────────────────────
== Department Breakdown

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 3fr),
  inset: 6pt,
  fill: (col, row) => if row == 0 { rgb("#1e40af").lighten(80%) },
  [*Department*], [*Headcount*], [*Budget*], [*Spent*], [*Notes*],
  [Engineering], [45], [\$180k], [\$172k], [Under budget — hiring freeze in Q3],
  [Sales], [28], [\$120k], [\$125k], [Over budget due to conference expenses],
  [Marketing], [15], [\$80k], [\$78k], [On track — digital campaigns performing well],
  [Operations], [12], [\$60k], [\$55k], [Efficiency gains from automation],
  [HR], [8], [\$40k], [\$38k], [New HRIS system deployed in Q2],
)

// ── Footer ──────────────────────────────────────────────────
#v(2em)
#align(center)[
  #text(8pt, fill: gray)[
    Generated on #vars.date · Confidential · #vars.name
  ]
]
