// =============================================================
// TEST FILE — simulates what the Rust compiler produces:
//   vars dict prepended  +  v1.0.0.typ body appended
// Run:  typst compile _test_compile.typ _test_compile.pdf
// =============================================================
#import "@preview/tiaoma:0.3.0": qrcode
#import "@preview/cetz:0.3.4": canvas, draw

#let vars = (
  // Period
  period_start:     "October 1, 2016",
  period_end:       "December 31, 2016",
  period_end_label: "Dec 31, 2016",
  base_date:        "Jan 1, 2016",

  // Account
  account_number:   "5150064",
  account_type:     "Registered Retirement Savings Plan",

  // Client
  client_name:      "JOHN D. WILSON",
  address_line1:    "105 – 123 KING STREET",
  address_city:     "OSHAWA ON  L1H 3Z3",

  // Balances
  ending_balance:   "$51,260.78",
  change_in_value:  "$1,832.74",
  ytd_change:       "$2,147.45",

  // Rates of return
  rate_this_period: "1.10%",
  rate_12_months:   "4.14%",
  rate_since_start: "4.14%",
)

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

#let section-head(t) = {
  text(size: 13pt, weight: "bold", fill: td-green)[#t]
  v(0.4em)
}

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

#let postal-barcode() = {
  let base = (1, 0, 2, 3, 1, 2, 0, 3, 1, 0, 2, 1, 3, 0, 1, 3, 2, 0, 1, 2)
  let pattern = ()
  for _ in range(9) { pattern = pattern + base }

  let bw    = 1.5
  let gap   = 0.75
  let fh    = 11.0
  let hh    = 5.5

  canvas(length: 0.65mm, {
    import draw: *
    for i in range(pattern.len()) {
      let x  = i * (bw + gap)
      let bt = pattern.at(i)
      let y0 = if bt == 2 { hh - 0.5 } else if bt == 3 { hh - 2.0 } else { 0.0 }
      let y1 = if bt == 1 { hh + 0.5 } else if bt == 3 { hh + 2.0 } else { fh   }
      rect((x, y0), (x + bw, y1), fill: td-dark, stroke: none)
    }
  })
}

#let performance-chart() = {
  canvas(length: 1cm, {
    import draw: *

    let W    = 9.5
    let H    = 5.4
    let PL   = 1.45
    let PB   = 0.72
    let ymin = 40000.0
    let ymax = 60000.0
    let xN   = 12

    let yw = H - PB
    let xw = W - PL

    rect((PL, PB), (W, H), fill: luma(252), stroke: 0.4pt + luma(210))

    let yticks = (40000, 45000, 50000, 55000, 60000)
    let ylbls  = ("$40,000", "$45,000", "$50,000", "$55,000", "$60,000")
    for i in range(yticks.len()) {
      let yv   = yticks.at(i)
      let ypos = PB + (yv - ymin) / (ymax - ymin) * yw
      line((PL, ypos), (W, ypos), stroke: 0.3pt + luma(215))
      content(
        (PL - 0.12, ypos), anchor: "east",
        text(size: 5.5pt, fill: td-gray)[#ylbls.at(i)]
      )
    }

    content((PL,           PB - 0.12), anchor: "north",
      text(size: 5.5pt, fill: td-gray)[Jan#linebreak()2016])
    content((PL + xw / 2,  PB - 0.12), anchor: "north",
      text(size: 5.5pt, fill: td-gray)[Jun#linebreak()2016])
    content((W,            PB - 0.12), anchor: "north",
      text(size: 5.5pt, fill: td-gray)[Dec#linebreak()2016])

    let pt(d) = (
      PL + d.at(0) / xN * xw,
      PB + (d.at(1) - ymin) / (ymax - ymin) * yw,
    )

    let mv = (
      (0,  49113.33), (1,  48620.0), (2,  49120.0), (3,  49750.0),
      (4,  49420.0),  (5,  50180.0), (6,  50480.0), (7,  50090.0),
      (8,  50720.0),  (9,  50960.0), (10, 50580.0), (11, 51080.0),
      (12, 51260.78),
    )

    let ic = (
      (0,  48222.33), (1,  48290.0), (2,  48350.0), (3,  48400.0),
      (4,  48450.0),  (5,  48490.0), (6,  48500.0), (7,  48530.0),
      (8,  48552.0),  (9,  48580.0), (10, 48600.0), (11, 48613.0),
      (12, 48613.0),
    )

    for i in range(mv.len() - 1) {
      line(pt(mv.at(i)), pt(mv.at(i + 1)), stroke: 2pt + td-green)
    }
    for i in range(ic.len() - 1) {
      line(pt(ic.at(i)), pt(ic.at(i + 1)), stroke: 1.4pt + td-dark)
    }

    let m-end = pt(mv.last())
    let i-end = pt(ic.last())

    content(
      (m-end.at(0) + 0.12, m-end.at(1) + 0.16), anchor: "west",
      text(size: 6pt, weight: "bold", fill: td-green)[\$51,260.78]
    )
    content(
      (i-end.at(0) + 0.12, i-end.at(1) - 0.22), anchor: "west",
      text(size: 6pt, fill: td-dark)[\$49,113.33]
    )
  })
}

// ══════════════════════════════════════════════════════════════
// POSTAL BARCODE in left margin
// ══════════════════════════════════════════════════════════════
#place(
  top + left,
  dx: -18mm,
  dy:   8mm,
  rotate(-90deg, postal-barcode()),
)

// ══════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════
#grid(
  columns: (3.3cm, 1fr),
  column-gutter: 0.5cm,
  align(top + left,
    block(
      width: 3.1cm, height: 3.1cm,
      fill: td-green, radius: 6pt,
      align(center + horizon,
        text(size: 32pt, weight: "bold", fill: white)[TD]
      )
    )
  ),
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
// ADDRESS  +  INFO BOXES
// ══════════════════════════════════════════════════════════════
#grid(
  columns: (1fr, 6.5cm),
  column-gutter: 1.2cm,
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
  block[
    #callout(
      "Do you have a question?",
      title-color: td-green, border-color: td-green, bg: white,
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
      title-color: td-orange, border-color: td-orange, bg: td-orange-bg,
    )[
      Please see page 4 for important information about your account.
    ]
  ],
)

#v(0.45cm)

// ══════════════════════════════════════════════════════════════
// ACCOUNT AT A GLANCE
// ══════════════════════════════════════════════════════════════
#section-head("Your account at a glance")

#grid(
  columns: (4.9cm, 1fr),
  column-gutter: 0.55cm,
  block(
    width: 100%, fill: td-silver, inset: 12pt, radius: 5pt,
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
  {
    set text(size: 8pt)
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
      align(right, text(weight: "bold")[#vars.at("ending_balance", default: "$51,260.78")]),
      align(right, text(weight: "bold")[#vars.at("ending_balance", default: "$51,260.78")]),
      align(right, text(weight: "bold")[#vars.at("ending_balance", default: "$51,260.78")]),
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

#block(
  width: 100%, inset: (x: 10pt, y: 8pt),
  radius: 3pt, stroke: 1pt + td-green, fill: td-green-light,
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
// PERFORMANCE CHART  +  RATES OF RETURN
// ══════════════════════════════════════════════════════════════
#grid(
  columns: (1fr, 6.8cm),
  column-gutter: 0.7cm,

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
    grid(
      columns: (12pt, auto, 12pt, 1fr),
      column-gutter: 4pt,
      align(horizon, rect(width: 12pt, height: 3pt, fill: td-green, stroke: none)),
      align(left + horizon, text(size: 6.5pt, fill: td-gray)[Market value of your account]),
      align(horizon, rect(width: 12pt, height: 3pt, fill: td-dark, stroke: none)),
      align(left + horizon,
        text(size: 6.5pt, fill: td-gray)[
          Your invested capital (total deposits less total withdrawals,
          including fees and charges)
        ]
      ),
    )
  }),

  block(width: 100%, {
    section-head[Your personal rates of return \ as of Dec 31, 2016]
    v(0.3em)
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
      text(size: 20pt, weight: "bold", fill: td-green)[#vars.at("rate_this_period", default: "1.10%")],
      text(size: 20pt, weight: "bold", fill: td-green)[#vars.at("rate_12_months",   default: "4.14%")],
      text(size: 20pt, weight: "bold", fill: td-green)[#vars.at("rate_since_start", default: "4.14%")],
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
    specified time period, net of fees and charges paid. Rates of return are provided on
    an annualized basis except for any returns reflective of a period of less than one
    year.]
  }),
)

#v(0.6cm)

// ══════════════════════════════════════════════════════════════
// FOOTER
// ══════════════════════════════════════════════════════════════
#td-rule
#v(0.35em)
#grid(
  columns: (auto, 1fr, auto),
  column-gutter: 0.75cm,
  align(left + horizon,
    qrcode(vars.at("account_number", default: "5150064"), width: 1.4cm)
  ),
  align(center + horizon)[
    #set text(size: 7pt, fill: td-gray)
    #vars.at("client_name", default: "JOHN D. WILSON")
    #h(0.4em)·#h(0.4em)
    Account #vars.at("account_number", default: "5150064")
    #h(0.4em)·#h(0.4em)
    #vars.at("period_start", default: "October 1, 2016") to
    #vars.at("period_end",   default: "December 31, 2016")
  ],
  align(right + horizon,
    text(size: 8.5pt, fill: td-gray)[Page 1 of 5]
  ),
)
