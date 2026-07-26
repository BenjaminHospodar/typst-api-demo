INSERT INTO templates(form,version,typ_source,schema,active) VALUES('contract','1.0.0',$typ$
#set page(paper: "a4", margin: (x: 1.5cm, y: 2cm))
#set text(size: 9pt)

// â”€â”€ Multi-page stress test â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#align(center)[
  #text(28pt, weight: "bold")[#vars.name]
  #v(0.3em)
  #text(12pt)[Contract Agreement â€” #vars.date]
]

#line(length: 100%)
#v(1em)

// Page 1: Dense text
== Article 1 â€” Definitions

#lorem(200)

#v(0.5em)

== Article 2 â€” Scope of Work

#vars.at("text1", default: [The contractor agrees to provide the following services as outlined in this agreement. All work shall be performed in accordance with industry standards and best practices.])

#lorem(150)

#pagebreak()

// Page 2: Complex tables
== Article 3 â€” Payment Schedule

#table(
  columns: (auto, 1fr, 1fr, 1fr, auto),
  inset: 6pt,
  fill: (col, row) => if row == 0 { rgb("#0f172a").lighten(85%) } else if calc.rem(row, 2) == 0 { rgb("#f8fafc") },
  [*#*], [*Milestone*], [*Deliverable*], [*Due Date*], [*Amount*],
  [1], [Project Kickoff], [Requirements Document], [Week 2], [\$15,000],
  [2], [Design Phase], [UI/UX Mockups], [Week 6], [\$25,000],
  [3], [Development Sprint 1], [Core Features], [Week 12], [\$35,000],
  [4], [Development Sprint 2], [Integration], [Week 18], [\$35,000],
  [5], [Testing & QA], [Test Reports], [Week 22], [\$20,000],
  [6], [Deployment], [Production Release], [Week 24], [\$15,000],
  [7], [Post-Launch Support], [30-day Support], [Week 28], [\$10,000],
  [8], [Final Handoff], [Documentation], [Week 30], [\$5,000],
)

#v(1em)
*Total Contract Value: \$160,000*

#v(1em)

== Article 4 â€” Terms and Conditions

#lorem(300)

#pagebreak()

// Page 3: More dense content + formatting
== Article 5 â€” Intellectual Property

#lorem(250)

#v(1em)

== Article 6 â€” Confidentiality

All proprietary information shared between parties shall remain confidential for a period of five (5) years from the date of this agreement. This includes but is not limited to:

#list(
  [Trade secrets and proprietary algorithms],
  [Customer lists and financial projections],
  [Technical specifications and architecture documents],
  [Marketing strategies and business development plans],
  [Employee compensation data and organizational charts],
)

#v(1em)

#lorem(200)

#v(2em)
#line(length: 100%)
#v(1em)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 2cm,
  [
    *For #vars.name:*
    #v(2em)
    #line(length: 80%)
    Signature
    #v(0.5em)
    Date: \_\_\_\_\_\_\_\_\_\_
  ],
  [
    *For Contractor:*
    #v(2em)
    #line(length: 80%)
    Signature
    #v(0.5em)
    Date: \_\_\_\_\_\_\_\_\_\_
  ],
)

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

INSERT INTO templates(form,version,typ_source,schema,active) VALUES('dashboard','1.0.0',$typ$
#set page(paper: "a4", margin: (x: 2cm, y: 2cm))
#set text(size: 10pt)
#set par(justify: true)

// â”€â”€ Dashboard-style template with computed layouts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#align(center)[
  #text(22pt, weight: "bold")[#vars.name]
  #v(0.3em)
  #text(11pt, fill: gray)[Analytics Dashboard â€” #vars.date]
]

#v(1em)

// â”€â”€ KPI Cards row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Large data table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Two-column insights â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#v(2em)
#line(length: 100%, stroke: 0.5pt + gray)
#v(0.5em)
#text(8pt, fill: gray)[
  #vars.name Â· Generated #vars.date Â· Page #counter(page).display() of #locate(loc => counter(page).final(loc).first())
]

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

INSERT INTO templates(form,version,typ_source,schema,active) VALUES('invoice','2.0.0',$typ$
#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm))
#set text(size: 11pt)
#set par(justify: true)

= #vars.name

*Date:* #vars.date

#vars.at("text1", default: "")

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

INSERT INTO templates(form,version,typ_source,schema,active) VALUES('invoice','2.1.0',$typ$
#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm))
#set text(font: "Liberation Sans", size: 11pt)
#set par(justify: true)

// â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
= #vars.name

*Date:* #vars.date \
*Terms:* #vars.at("text3", default: "")

// â”€â”€ Conditional layout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#if vars.at("draft", default: "false") == "true" [
  #place(center + horizon, rotate(45deg,
    text(80pt, fill: red.transparentize(70%))[DRAFT]
  ))
]

// â”€â”€ Body text â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#vars.at("text1", default: "")

#v(1em)

// â”€â”€ Conditional section (only renders if text4 is provided) â”€
#if vars.at("text4", default: "") != "" [
  *Payment notes:* #vars.text4
]

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

INSERT INTO templates(form,version,typ_source,schema,active) VALUES('minimal','1.0.0',$typ$
#set page(paper: "a4", margin: (x: 2cm, y: 2cm))
#set text(size: 10pt)
#set par(justify: true)

// â”€â”€ Minimal fast template for TPS benchmarks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
= #vars.name

*Date:* #vars.date

#vars.at("text1", default: "Benchmark document for throughput testing.")

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

INSERT INTO templates(form,version,typ_source,schema,active) VALUES('report','1.0.0',$typ$
#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm))
#set text(size: 11pt)
#set par(justify: true)

= Report: #vars.name

*Generated:* #vars.date

#vars.at("text1", default: "No content provided.")

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

INSERT INTO templates(form,version,typ_source,schema,active) VALUES('report','2.0.0',$typ$
#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm))
#set text(size: 10pt)
#set par(justify: true)

// â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#align(center)[
  #text(24pt, weight: "bold")[#vars.name]
  #v(0.5em)
  #text(14pt, fill: gray)[Quarterly Financial Report â€” #vars.date]
]

#line(length: 100%)
#v(1em)

// â”€â”€ Summary Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Multi-column layout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Nested tables â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
== Department Breakdown

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 3fr),
  inset: 6pt,
  fill: (col, row) => if row == 0 { rgb("#1e40af").lighten(80%) },
  [*Department*], [*Headcount*], [*Budget*], [*Spent*], [*Notes*],
  [Engineering], [45], [\$180k], [\$172k], [Under budget â€” hiring freeze in Q3],
  [Sales], [28], [\$120k], [\$125k], [Over budget due to conference expenses],
  [Marketing], [15], [\$80k], [\$78k], [On track â€” digital campaigns performing well],
  [Operations], [12], [\$60k], [\$55k], [Efficiency gains from automation],
  [HR], [8], [\$40k], [\$38k], [New HRIS system deployed in Q2],
)

// â”€â”€ Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
#v(2em)
#align(center)[
  #text(8pt, fill: gray)[
    Generated on #vars.date Â· Confidential Â· #vars.name
  ]
]

$typ$,'{}',true) ON CONFLICT(form,version) DO UPDATE SET typ_source=EXCLUDED.typ_source;

