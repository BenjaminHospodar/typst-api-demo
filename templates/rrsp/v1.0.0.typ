// ============================================================
// TD Mutual Funds — RRSP Statement  v1.0.0
// Typst 0.12  |  TD Emerald branding
//
// Phase 1: no Typst Universe packages. QR/chart are native placeholders.
// Fields bind via sidecar sys.inputs.data (JSON string).
// ============================================================

#let vars = json.decode(sys.inputs.at("data", default: "{}"))

// ══════════════════════════════════════════════════════════════
// TD EMERALD PALETTE
// ══════════════════════════════════════════════════════════════
#let td-green        = rgb("#00703c")
#let td-green-mid    = rgb("#005c32")
#let td-green-light  = rgb("#e6f2eb")
#let td-orange       = rgb("#c45000")
#let td-orange-bg    = rgb("#fff4eb")
#let td-dark         = rgb("#1a1a1a")
#let td-gray         = rgb("#5f5f5f")
#let td-silver       = rgb("#f1f1f1")
#let td-rule-color   = rgb("#d0d0d0")

// ══════════════════════════════════════════════════════════════
// PAGE SETUP
// ══════════════════════════════════════════════════════════════
#set page(
  paper: "a4",
  margin: (left: 20mm, right: 15mm, top: 11mm, bottom: 13mm),
)
#set text(size: 9pt, fill: td-dark)
#set par(justify: false, leading: 0.52em)

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════
#let td-rule = line(length: 100%, stroke: 0.5pt + td-rule-color)

// Section heading in TD green
#let section-head(t) = {
  text(size: 13pt, weight: "bold", fill: td-green)[#t]
  v(0.4em)
}

// Bordered callout box
#let callout(title, body,
  title-color: td-green,
  border-color: td-green,
  bg: white,
) = block(
  width: 100%,
  inset: (x: 10pt, y: 8pt),
  radius: 3pt,
  stroke: 1pt + border-color,
  fill: bg,
)[
  #text(weight: "bold", size: 8.5pt, fill: title-color)[#title]
  #v(0.28em)
  #set text(size: 8.5pt, fill: td-dark)
  #body
]

// ── Native 4-state postal barcode stand-in (no cetz) ────────
#let postal-barcode() = {
  let base = (1, 0, 2, 3, 1, 2, 0, 3, 1, 0, 2, 1, 3, 0, 1, 3, 2, 0, 1, 2)
  let pattern = ()
  for _ in range(9) { pattern = pattern + base }
  let unit = 1.15pt
  box(width: 207mm, height: 7mm, {
    for i in range(pattern.len()) {
      let bt = pattern.at(i)
      let y0 = if bt == 2 { 3.2mm } else if bt == 3 { 2.2mm } else { 0mm }
      let y1 = if bt == 1 { 3.8mm } else if bt == 3 { 4.8mm } else { 7mm }
      place(
        dx: i * unit,
        dy: y0,
        rect(width: 0.9pt, height: y1 - y0, fill: td-dark, stroke: none),
      )
    }
  })
}

// ── Native performance-chart placeholder (no cetz) ───────────
#let performance-chart() = {
  block(
    width: 100%,
    height: 5.4cm,
    fill: luma(252),
    stroke: 0.4pt + luma(210),
    inset: 10pt,
    align(center + horizon)[
      #text(size: 8pt, fill: td-gray)[Account performance chart]
      #v(0.3em)
      #text(size: 7pt, fill: td-gray)[Native placeholder — Universe packages are not resolved in-service]
    ],
  )
}

// ══════════════════════════════════════════════════════════════
// POSTAL BARCODE — placed in left margin, running top-to-bottom
// ══════════════════════════════════════════════════════════════
// The barcode canvas is ~207 mm wide × ~7 mm tall.  Rotating it
// –90° makes it ~7 mm wide × ~207 mm tall.  Placing with a
// negative dx pushes it into the 20 mm left margin.
#place(
  top + left,
  dx: -18mm,
  dy:   8mm,
  rotate(-90deg, postal-barcode()),
)

// ══════════════════════════════════════════════════════════════
// HEADER — TD logo  ·  statement title  ·  account info
// ══════════════════════════════════════════════════════════════
#grid(
  columns: (3.3cm, 1fr),
  column-gutter: 0.5cm,

  // TD Logo block
  align(top + left,
    block(
      width: 3.1cm, height: 3.1cm,
      fill: td-green, radius: 6pt,
      align(center + horizon,
        text(size: 32pt, weight: "bold", fill: white)[TD]
      )
    )
  ),

  // Title + account metadata
  align(top + right)[
    #v(0.15em)
    #text(size: 18pt, weight: "bold", fill: td-green)[Your TD Mutual Funds RRSP statement]
    #v(0.5em)
    #text(size: 10.5pt)[
      #vars.at("period_start", default: "October 1, 2016") to
      #vars.at("period_end",   default: "December 31, 2016")
    ]
    #v(0.3em)
    #set text(size: 8.5pt, fill: td-gray)
    Account number: #vars.at("account_number", default: "5150064") \
    Account type: #vars.at("account_type", default: "Registered Retirement Savings Plan")
  ],
)

#v(0.3cm)
#td-rule
#v(0.3cm)

// ══════════════════════════════════════════════════════════════
// ADDRESS BLOCK  +  CONTACT INFO BOXES
// ══════════════════════════════════════════════════════════════
#grid(
  columns: (1fr, 6.5cm),
  column-gutter: 1.2cm,

  // Mailing address
  block[
    #text(size: 7pt, fill: td-gray)[T0XX10000_0000000_001 E 00000]
    #v(0.6em)
    #text(size: 9.5pt, weight: "bold")[#vars.at("client_name", default: "JOHN D. WILSON")]
    #v(0.15em)
    #text(size: 9.5pt)[
      #vars.at("address_line1", default: "105 – 123 KING STREET") \
      #vars.at("address_city",  default: "OSHAWA ON  L1H 3Z3")
    ]
  ],

  // Info callout boxes
  block[
    #callout(
      "Do you have a question?",
      title-color: td-green,
      border-color: td-green,
      bg: white,
    )[
      For questions about your statement or information about TD Mutual Funds,
      please contact TD Investment Services Inc.
      #v(0.25em)
      *1-844-352-1748*
      #v(0.25em)
      Would you like to learn more about your statement? \
      Visit *www.td.com/mutualfunds*
    ]
    #v(0.35em)
    #callout(
      "⚠  You need to know",
      title-color: td-orange,
      border-color: td-orange,
      bg: td-orange-bg,
    )[
      Please see page 4 for important information about your account.
    ]
  ],
)

#v(0.45cm)

// ══════════════════════════════════════════════════════════════
// YOUR ACCOUNT AT A GLANCE
// ══════════════════════════════════════════════════════════════
#section-head("Your account at a glance")

#grid(
  columns: (4.9cm, 1fr),
  column-gutter: 0.55cm,

  // ── Green value highlight box ──────────────────────────────
  block(
    width: 100%,
    fill: td-silver,
    inset: 12pt,
    radius: 5pt,
    {
      text(size: 9pt, weight: "bold", fill: td-green)[
        Value of your \
        account on \
        #vars.at("period_end_label", default: "Dec 31, 2016")
      ]
      v(0.65em)
      text(size: 23pt, weight: "bold", fill: td-green)[
        #vars.at("ending_balance", default: "$51,260.78")
      ]
    }
  ),

  // ── Summary table ──────────────────────────────────────────
  {
    set text(size: 8pt)

    // Column headers
    grid(
      columns: (1fr, 3.5cm, 3.5cm, 3.1cm),
      column-gutter: 0pt,
      [],
      align(right)[
        #text(weight: "bold", size: 7pt)[This Period]
        #linebreak()
        #text(fill: td-gray, size: 6.5pt)[(Oct 1 – Dec 31, 2016)]
      ],
      align(right)[
        #text(weight: "bold", size: 7pt)[Year to date]
        #linebreak()
        #text(fill: td-gray, size: 6.5pt)[(Jan 1 – Dec 31, 2016)]
      ],
      align(right)[
        #text(weight: "bold", size: 7pt)[Since]
        #linebreak()
        #text(fill: td-gray, size: 6.5pt)[Jan 1, 2016]
      ],
    )

    v(0.2em)
    line(length: 100%, stroke: 0.5pt + td-rule-color)

    // Data rows
    let rows = (
      ("Beginning balance",               "$50,618.43", "$48,222.33", "$48,222.33"),
      ("Deposits or contributions",        "$481.00",    "$1,391.00",  "$1,391.00"),
      ("Withdrawals",                      "–$490.00",   "–$490.00",   "–$490.00"),
      ("Fees and charges",                 "–$10.00",    "–$10.00",    "–$10.00"),
      ("Change in value of your account",  "$661.35",    "$2,147.45",  "$2,147.45"),
    )

    for r in rows {
      v(0.2em)
      grid(
        columns: (1fr, 3.5cm, 3.5cm, 3.1cm),
        column-gutter: 0pt,
        text[#r.at(0)],
        align(right, text[#r.at(1)]),
        align(right, text[#r.at(2)]),
        align(right, text[#r.at(3)]),
      )
      line(length: 100%, stroke: 0.3pt + td-rule-color)
    }

    v(0.2em)
    grid(
      columns: (1fr, 3.5cm, 3.5cm, 3.1cm),
      column-gutter: 0pt,
      text(weight: "bold")[Ending balance],
      align(right, text(weight: "bold")[
        #vars.at("ending_balance", default: "$51,260.78")
      ]),
      align(right, text(weight: "bold")[
        #vars.at("ending_balance", default: "$51,260.78")
      ]),
      align(right, text(weight: "bold")[
        #vars.at("ending_balance", default: "$51,260.78")
      ]),
    )
    line(length: 100%, stroke: 1.2pt + td-dark)
  },
)

#v(0.3em)
#text(size: 7.5pt, fill: td-gray)[
  ▸ This summary reflects both US and Canadian holdings \
  ▸ US dollars converted to Canadian dollars at 1.38 as of Dec 31, 2016
]

#v(0.4em)

// ── Change in value callout ────────────────────────────────────
#block(
  width: 100%,
  inset: (x: 10pt, y: 8pt),
  radius: 3pt,
  stroke: 1pt + td-green,
  fill: td-green-light,
)[
  #set text(size: 8.5pt)
  #text(weight: "bold")[
    ⊕ Change in value of investments: #vars.at("change_in_value", default: "$1,832.74").
  ]
  At the statement date, we subtract the book cost of your investments from the market
  value to determine the unrealized gain or loss. For additional information, please see
  page 2 of your statement.
]

#v(0.45cm)

// ══════════════════════════════════════════════════════════════
// HOW YOUR ACCOUNT HAS PERFORMED  +  RATES OF RETURN
// ══════════════════════════════════════════════════════════════
#grid(
  columns: (1fr, 6.8cm),
  column-gutter: 0.7cm,

  // ── Left: portfolio line chart ────────────────────────────
  block(width: 100%, {
    section-head("How your account has performed")
    text(size: 8.5pt)[
      Your account has changed in value by
      *#vars.at("ytd_change", default: "$2,147.45")* since
      #vars.at("base_date",   default: "Jan 1, 2016").
    ]
    v(0.45em)
    performance-chart()
    v(0.35em)

    // Legend
    grid(
      columns: (12pt, auto, 12pt, 1fr),
      column-gutter: 4pt,
      align(horizon,
        rect(width: 12pt, height: 3pt, fill: td-green, stroke: none)
      ),
      align(left + horizon,
        text(size: 6.5pt, fill: td-gray)[Market value of your account]
      ),
      align(horizon,
        rect(width: 12pt, height: 3pt, fill: td-dark, stroke: none)
      ),
      align(left + horizon,
        text(size: 6.5pt, fill: td-gray)[
          Your invested capital (total deposits less total withdrawals,
          including fees and charges)
        ]
      ),
    )
  }),

  // ── Right: personal rates of return ──────────────────────
  block(width: 100%, {
    section-head[Your personal rates of return \ as of Dec 31, 2016]
    v(0.3em)

    // Three-column rates table
    table(
      stroke: none,
      columns: (1fr, 1fr, 1fr),
      inset: (x: 5pt, y: 9pt),
      fill: (col, row) => if row == 0 { td-silver } else { white },
      align: center,
      table.header(
        text(size: 7pt, weight: "bold")[For this #linebreak() period],
        text(size: 7pt, weight: "bold")[For the last #linebreak() 12 months],
        text(size: 7pt, weight: "bold")[Since #linebreak() Jan 1, 2016],
      ),
      text(size: 20pt, weight: "bold", fill: td-green)[
        #vars.at("rate_this_period", default: "1.10%")
      ],
      text(size: 20pt, weight: "bold", fill: td-green)[
        #vars.at("rate_12_months",   default: "4.14%")
      ],
      text(size: 20pt, weight: "bold", fill: td-green)[
        #vars.at("rate_since_start", default: "4.14%")
      ],
    )

    v(0.55em)
    set text(size: 7.5pt, fill: td-gray)

    [Personal rate of return reflects the total percentage return earned on the
    investments held in your account. Total percentage return means the cumulative
    realized and unrealized capital gains and losses of an investment, plus income from
    the investment, over a specified period of time, expressed as a percentage.
    #v(0.35em)
    Personal rate of return is calculated using a money-weighted methodology. Unlike
    alternative rate of return methodologies, it takes into account any deposits or
    withdrawals you have made, and the performance outcomes of your investments over a
    specified time period, net of fees and charges paid. Rates of return are provided
    on an annualized basis except for any returns reflective of a period of less than
    one year.]
  }),
)

#v(0.6cm)

// ══════════════════════════════════════════════════════════════
// FOOTER — QR code  ·  account identifier  ·  page number
// ══════════════════════════════════════════════════════════════
#td-rule
#v(0.35em)

#grid(
  columns: (auto, 1fr, auto),
  column-gutter: 0.75cm,

  // QR code (encodes account number for digital scanning)
  align(left + horizon,
    rect(
      width: 1.4cm,
      height: 1.4cm,
      stroke: 0.7pt + td-dark,
      inset: 2pt,
      align(center + horizon, text(size: 6pt, fill: td-gray)[QR]),
    )
  ),

  // Central account identifier line
  align(center + horizon)[
    #set text(size: 7pt, fill: td-gray)
    #vars.at("client_name",    default: "JOHN D. WILSON")
    #h(0.4em)·#h(0.4em)
    Account #vars.at("account_number", default: "5150064")
    #h(0.4em)·#h(0.4em)
    #vars.at("period_start", default: "October 1, 2016") to
    #vars.at("period_end",   default: "December 31, 2016")
  ],

  // Page indicator
  align(right + horizon,
    text(size: 8.5pt, fill: td-gray)[Page 1 of 5]
  ),
)
