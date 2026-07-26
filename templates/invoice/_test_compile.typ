// =============================================================
// TEST FILE — simulates what the Rust compiler produces:
//   vars dict prepended  +  v2.1.0.typ body appended
// Run:  typst compile _test_compile.typ _test_compile.pdf
// =============================================================
#import "@preview/tiaoma:0.3.0": qrcode

#let vars = (
  sender_name:       "TD Bank, N.A.",
  sender_address:    "123 TD Bank Street",
  sender_city:       "Toronto, ON  M5K 1A2",
  sender_phone:      "Tel: 1-800-TD-BANKS",
  sender_email:      "www.td.com",
  recipient:         "Acme Corp",
  recipient_name:    "Acme Corp",
  recipient_address: "100 Main Street, Suite 400",
  recipient_city:    "New York, NY 10005",
  name:              "TD Bank, N.A.",
  date:              "April 15, 2026",
  invoice_number:    "INV-2026-001",
  text3:             "Net 30",
  due_date:          "May 15, 2026",
  draft:             "false",
  text1:             "Commercial Banking Services — Q2 2026",
  quantity:          "1",
  unit_price:        "$5,200.00",
  amount:            "$5,200.00",
  text2:             "",
  quantity2:         "1",
  unit_price2:       "",
  amount2:           "",
  subtotal:          "$5,200.00",
  tax_rate:          "0",
  tax_amount:        "$0.00",
  total:             "$5,200.00",
  text4:             "Please remit payment via wire transfer. Include invoice number as reference.",
  account_holder:    "TD Bank Client Services",
  account_number:    "****7890",
  transit_number:    "00123",
  institution_number:"004",
  iban:              "CA00 1234 5678 9012",
  reference:         "INV-2026-001",
)

// ============================================================
// TD Bank — Professional English Invoice
// Mirrors invoice-pro layout: header, address block, items,
// totals, bank details, footer.
// vars dict is prepended by the Rust compiler at render time.
// ============================================================

#let td-green = rgb("#00703c")
#let td-dark  = rgb("#1a1a1a")
#let td-gray  = luma(110)
#let td-rule  = rgb("#cccccc")

// ── page setup ───────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (left: 25mm, right: 20mm, top: 16mm, bottom: 20mm),
)
#set text(size: 10.5pt, fill: td-dark)
#set par(justify: true, leading: 0.55em)

// ── draft watermark ──────────────────────────────────────────
#if vars.at("draft", default: "false") == "true" {
  place(center + horizon, rotate(45deg,
    text(80pt, fill: red.transparentize(70%), weight: "bold")[DRAFT]
  ))
}

// ════════════════════════════════════════════════════════════
// HEADER  — logo left · sender address right
// ════════════════════════════════════════════════════════════
#grid(
  columns: (auto, 1fr),
  column-gutter: 1.2cm,
  rows: (auto,),
  align(top + left,
    image("image.png", width: 4cm)
  ),
  align(top + right)[
    #text(size: 9pt, fill: td-gray)[
      #vars.at("sender_name",   default: "TD Bank") \
      #vars.at("sender_address",default: "123 TD Bank Street") \
      #vars.at("sender_city",   default: "Toronto, ON  M5K 1A2") \
      #vars.at("sender_phone",  default: "Tel: 1-800-TD-BANKS") \
      #vars.at("sender_email",  default: "www.td.com")
    ]
  ],
)

#v(0.6cm)
#line(length: 100%, stroke: 2pt + td-green)
#v(0.5cm)

// ════════════════════════════════════════════════════════════
// ADDRESS + INVOICE META
// ════════════════════════════════════════════════════════════
#grid(
  columns: (1fr, 6.5cm),
  column-gutter: 1cm,
  block[
    #text(size: 7.5pt, fill: td-gray, tracking: 1pt)[BILL TO]
    #v(0.25em)
    #text(size: 10.5pt, weight: "bold")[#vars.at("recipient_name", default: vars.at("recipient", default: ""))]
    #v(0.1em)
    #text(size: 9.5pt)[
      #vars.at("recipient_address", default: "") \
      #vars.at("recipient_city",    default: "")
    ]
  ],
  block[
    #set text(size: 9.5pt)
    #table(
      stroke: none,
      columns: (auto, 1fr),
      inset: (x: 0pt, y: 3pt),
      align: (left, right),
      [*Invoice No.*],  [#vars.at("invoice_number", default: "")],
      [*Date*],         [#vars.date],
      [*Terms*],        [#vars.at("text3", default: "")],
      [*Due Date*],     [#vars.at("due_date", default: "On Receipt")],
    )
    #line(length: 100%, stroke: 0.5pt + td-rule)
    #v(0.3em)
    #align(right)[
      #text(size: 9pt, fill: td-gray)[Amount Due]
      #v(0.1em)
      #text(size: 18pt, weight: "bold", fill: td-green)[
        #vars.at("total", default: "")
      ]
    ]
  ],
)

#v(0.7cm)

// ════════════════════════════════════════════════════════════
// LINE ITEMS TABLE
// ════════════════════════════════════════════════════════════
#block(width: 100%, {
  set text(size: 9.5pt)
  table(
    stroke: none,
    columns: (auto, 1fr, auto, auto, auto),
    inset: (x: 5pt, y: 5pt),
    align: (center, left, right, right, right),
    table.header(
      table.hline(stroke: 0.5pt + td-dark),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[#h(0em)*#[No.]*#h(0em)]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Description]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Qty]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Unit Price]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Amount]),
      table.hline(stroke: 0pt),
    ),
    [1],
    [#vars.at("text1", default: "")],
    [#vars.at("quantity",   default: "1")],
    [#vars.at("unit_price", default: "")],
    [#vars.at("amount",     default: "")],
    ..if vars.at("text2", default: "") != "" {
      (
        [2],
        [#vars.at("text2",       default: "")],
        [#vars.at("quantity2",   default: "1")],
        [#vars.at("unit_price2", default: "")],
        [#vars.at("amount2",     default: "")],
      )
    },
    table.footer(
      table.hline(stroke: 0.5pt + td-dark),
      [], [], [], [], [],
    ),
  )
})

// ════════════════════════════════════════════════════════════
// TOTALS
// ════════════════════════════════════════════════════════════
#v(0.4em)
#align(right, block(width: 7cm, {
  set text(size: 9.5pt)
  table(
    stroke: none,
    columns: (1fr, auto),
    inset: (x: 5pt, y: 3.5pt),
    align: (left, right),
    [Subtotal],
    [#vars.at("subtotal", default: "")],
    [Tax (#vars.at("tax_rate", default: "0") %)],
    [#vars.at("tax_amount", default: "")],
    table.hline(stroke: 0.5pt + td-dark),
    table.cell(text(weight: "bold")[Total (USD)]),
    table.cell(text(weight: "bold", fill: td-green)[#vars.at("total", default: "")]),
    table.hline(stroke: 2pt + td-dark),
  )
}))

#v(0.5cm)

// ════════════════════════════════════════════════════════════
// PAYMENT NOTES
// ════════════════════════════════════════════════════════════
#if vars.at("text4", default: "") != "" {
  block(
    width: 100%,
    fill: luma(245),
    inset: 10pt,
    radius: 3pt,
    {
      text(weight: "bold")[Payment Instructions]
      v(0.3em)
      text(size: 9.5pt)[#vars.text4]
    }
  )
  v(0.4cm)
}

// ════════════════════════════════════════════════════════════
// BANKING INFORMATION
// ════════════════════════════════════════════════════════════
#line(length: 100%, stroke: 0.5pt + td-rule)
#v(0.3em)
#text(size: 8pt, fill: td-gray, tracking: 1pt)[BANKING INFORMATION]
#v(0.3em)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1cm,
  block[
    #set text(size: 9.5pt)
    #set par(leading: 0.7em)
    *Bank:* TD Canada Trust \
    *Account Holder:* #vars.at("account_holder",     default: "") \
    *Account No.:* #vars.at("account_number",          default: "") \
    *Transit No.:* #vars.at("transit_number",          default: "") \
    *Institution No.:* #vars.at("institution_number",  default: "") \
    *SWIFT / BIC:* TDOMCATTTOR
  ],
  block[
    #set text(size: 9.5pt)
    #set par(leading: 0.7em)
    *IBAN:* #vars.at("iban",       default: "") \
    *Reference:* #vars.at("reference", default: vars.at("invoice_number", default: "")) \
    \
    #text(size: 9pt, fill: td-gray)[
      Please include the invoice number as payment reference.
    ]
  ],
)

// ════════════════════════════════════════════════════════════
// FOOTER
// ════════════════════════════════════════════════════════════
#v(1fr)
#line(length: 100%, stroke: 0.5pt + td-rule)
#v(0.3em)
#grid(
  columns: (1fr, auto),
  column-gutter: 1cm,
  align(left + horizon, text(size: 8pt, fill: td-gray)[
    Thank you for your business. \
    Questions? Contact us at 1-800-TD-BANKS or visit #link("https://www.td.com")[www.td.com] \
    TD Bank, N.A. — Member FDIC
  ]),
  align(right + horizon,
    block({
      align(center, qrcode("https://www.td.com", width: 1.6cm))
      v(0.2em)
      align(center, text(size: 6.5pt, fill: td-gray)[Scan to visit td.com])
    })
  ),
)
