// ============================================================
// TD Bank — Professional English Invoice
// Mirrors invoice-pro layout: header, address block, items,
// totals, bank details, footer.
// Fields bind via sidecar sys.inputs.data. No Typst Universe packages.
// ============================================================

#let vars = json.decode(sys.inputs.at("data", default: "{}"))

#let td-green = rgb("#00703c")
#let td-dark  = rgb("#1a1a1a")
#let td-gray  = luma(110)
#let td-rule  = rgb("#cccccc")

// ── helpers ──────────────────────────────────────────────────
#let fmt-currency(n) = {
  // n is already a float string; format with 2 decimal places
  let f = float(n)
  let cents = str(calc.round(f * 100))
  let pad = if cents.len() < 3 { "0" * (3 - cents.len()) + cents } else { cents }
  let whole = pad.slice(0, pad.len() - 2)
  let frac  = pad.slice(pad.len() - 2)
  if whole == "" or whole == "-" { whole = whole + "0" }
  "$" + whole + "." + frac
}

// ── page setup ───────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (left: 25mm, right: 20mm, top: 16mm, bottom: 20mm),
)
#set text(size: 10.5pt, fill: td-dark)
#set par(justify: true, leading: 0.55em)

// ── draft watermark (placed before any content) ──────────────
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
  // Logo
  align(top + left,
    image("image.png", width: 4cm)
  ),
  // Sender block (top-right)
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
// ADDRESS + INVOICE META  (two-column, like DIN 5008)
// ════════════════════════════════════════════════════════════
#grid(
  columns: (1fr, 6.5cm),
  column-gutter: 1cm,
  // Bill To
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
  // Invoice meta table
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
// LINE ITEMS TABLE  (mirrors invoice-pro table structure)
// ════════════════════════════════════════════════════════════
#block(width: 100%, {
  set text(size: 9.5pt)
  table(
    stroke: none,
    columns: (auto, 1fr, auto, auto, auto),
    inset: (x: 5pt, y: 5pt),
    align: (center, left, right, right, right),
    // Header row
    table.header(
      table.hline(stroke: 0.5pt + td-dark),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[#h(0em)*#[No.]*#h(0em)]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Description]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Qty]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Unit Price]),
      table.cell(fill: td-green, text(fill: white, weight: "bold")[Amount]),
      table.hline(stroke: 0pt),
    ),
    // Body — text1 is the single line item description block
    [1],
    [#vars.at("text1", default: "")],
    [#vars.at("quantity", default: "1")],
    [#vars.at("unit_price", default: "")],
    [#vars.at("amount",     default: "")],
    // Extra items if provided
    ..if vars.at("text2", default: "") != "" {
      (
        [2],
        [#vars.at("text2", default: "")],
        [#vars.at("quantity2", default: "1")],
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
// TOTALS BLOCK  (right-aligned, mirrors invoice-pro footer)
// ════════════════════════════════════════════════════════════
#v(0.4em)
#align(right, block(width: 7cm, {
  set text(size: 9.5pt)
  table(
    stroke: none,
    columns: (1fr, auto),
    inset: (x: 5pt, y: 3.5pt),
    align: (left, right),
    [Subtotal],               [#vars.at("subtotal",   default: "")],
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
// BANKING INFORMATION  (mirrors invoice-pro bank-details)
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
    *Account Holder:* #vars.at("account_holder",    default: "") \
    *Account No.:* #vars.at("account_number",        default: "") \
    *Transit No.:* #vars.at("transit_number",        default: "") \
    *Institution No.:* #vars.at("institution_number",default: "") \
    *SWIFT / BIC:* TDOMCATTTOR
  ],
  block[
    #set text(size: 9.5pt)
    #set par(leading: 0.7em)
    *IBAN:* #vars.at("iban",      default: "") \
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
      align(center, rect(
        width: 1.6cm,
        height: 1.6cm,
        stroke: 0.7pt + td-dark,
        inset: 2pt,
        align(center + horizon, text(size: 6pt, fill: td-gray)[QR]),
      ))
      v(0.2em)
      align(center, text(size: 6.5pt, fill: td-gray)[Scan to visit td.com])
    })
  ),
)
