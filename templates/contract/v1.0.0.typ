#let vars = json.decode(sys.inputs.at("data", default: "{}"))

#set page(paper: "a4", margin: (x: 1.5cm, y: 2cm))
#set text(size: 9pt)

// ── Multi-page stress test ──────────────────────────────────
#align(center)[
  #text(28pt, weight: "bold")[#vars.name]
  #v(0.3em)
  #text(12pt)[Contract Agreement — #vars.date]
]

#line(length: 100%)
#v(1em)

// Page 1: Dense text
== Article 1 — Definitions

#lorem(200)

#v(0.5em)

== Article 2 — Scope of Work

#vars.at("text1", default: [The contractor agrees to provide the following services as outlined in this agreement. All work shall be performed in accordance with industry standards and best practices.])

#lorem(150)

#pagebreak()

// Page 2: Complex tables
== Article 3 — Payment Schedule

#table(
  columns: (auto, 1fr, 1fr, 1fr, auto),
  inset: 6pt,
  fill: (col, row) => if row == 0 { rgb("#0f172a").lighten(85%) } else if calc.rem(row, 2) == 0 { rgb("#f8fafc") },
  [*\#*], [*Milestone*], [*Deliverable*], [*Due Date*], [*Amount*],
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

== Article 4 — Terms and Conditions

#lorem(300)

#pagebreak()

// Page 3: More dense content + formatting
== Article 5 — Intellectual Property

#lorem(250)

#v(1em)

== Article 6 — Confidentiality

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
