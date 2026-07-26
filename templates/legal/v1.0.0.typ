// ── Legal Document Template v1.0.0 ──────────────────────────
// Two-page legal document with logo, charts, graphs, and
// two additional conditional-requirement pages.
//
// Required vars: name, date
// Text inputs: text1..text12 (all optional with defaults)
//   text1  = Document title / matter name
//   text2  = Jurisdiction / governing law
//   text3  = Party A (client) full name
//   text4  = Party B (counterparty) full name
//   text5  = Case / docket number
//   text6  = Executive summary paragraph
//   text7  = Risk assessment narrative
//   text8  = Financial exposure description
//   text9  = Compliance requirements
//   text10 = Conditions precedent
//   text11 = Conditions subsequent / termination triggers
//   text12 = Additional notes / special provisions

#set page(paper: "a4", margin: (x: 1.8cm, y: 2cm), numbering: "1 / 4")
#set text(size: 9pt, font: "Linux Libertine")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")

// ── Colour palette ──────────────────────────────────────────
#let navy   = rgb("#0b1e3e")
#let accent = rgb("#1a5276")
#let muted  = rgb("#5d6d7e")
#let warn   = rgb("#c0392b")
#let ok     = rgb("#27ae60")
#let pale   = rgb("#eaf2f8")

// ══════════════════════════════════════════════════════════════
//  PAGE 1 — COVER & EXECUTIVE OVERVIEW
// ══════════════════════════════════════════════════════════════

// ── Logo placeholder (circle seal) ──────────────────────────
#align(center)[
  #box(
    width: 60pt, height: 60pt, radius: 30pt,
    fill: navy, stroke: 2pt + accent,
  )[
    #align(center + horizon)[
      #text(20pt, weight: "bold", fill: white)[§]
    ]
  ]
  #v(0.4em)
  #text(9pt, fill: muted)[#vars.name — Legal Division]
]

#v(0.6em)
#align(center)[
  #text(22pt, weight: "bold", fill: navy)[
    #vars.at("text1", default: "Legal Memorandum & Risk Assessment")
  ]
  #v(0.3em)
  #text(11pt, fill: muted)[
    Prepared: #vars.date
    #h(2em)
    Ref: #vars.at("text5", default: "CASE-2024-00001")
  ]
]

#line(length: 100%, stroke: 1.5pt + navy)
#v(0.8em)

// ── Parties & jurisdiction ──────────────────────────────────
#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,
  [
    #text(weight: "bold", fill: accent)[Party A (Client)]
    #v(2pt)
    #vars.at("text3", default: "Apex Holdings International Ltd.")
    #v(6pt)
    #text(weight: "bold", fill: accent)[Party B (Counterparty)]
    #v(2pt)
    #vars.at("text4", default: "Zenith Capital Partners LLC")
  ],
  [
    #text(weight: "bold", fill: accent)[Governing Law]
    #v(2pt)
    #vars.at("text2", default: "State of Delaware, United States")
    #v(6pt)
    #text(weight: "bold", fill: accent)[Docket / Reference]
    #v(2pt)
    #vars.at("text5", default: "CASE-2024-00001")
  ],
)

#v(1em)

// ── Executive Summary (heavy text) ──────────────────────────
= Executive Summary

#vars.at("text6", default: [This memorandum provides a comprehensive legal analysis of the contractual obligations, regulatory compliance posture, and financial risk exposure arising from the proposed transaction between the parties identified above. The analysis covers jurisdictional considerations, applicable statutory frameworks, precedential case law, and quantified risk scenarios. All conclusions herein are subject to the assumptions and limiting conditions stated in Section 4.])

#v(0.6em)

This assessment has been prepared in accordance with the professional standards of the American Bar Association Model Rules of Professional Conduct, Rule 2.1, and reflects independent legal judgment exercised with due diligence. The matters discussed herein are privileged and confidential under the attorney–client privilege and work-product doctrine.

#v(0.8em)

// ── Risk Matrix Chart ───────────────────────────────────────
== Risk Assessment Matrix

#vars.at("text7", default: [The following matrix illustrates the probability-impact distribution across six identified risk categories. Each category has been scored on a five-point Likert scale for both likelihood of occurrence and severity of financial or reputational impact.])

#v(0.4em)

// Horizontal bar chart — risk categories
#{
  let risks = (
    ("Regulatory Non-Compliance", 85, warn),
    ("Contractual Breach Exposure", 72, rgb("#e67e22")),
    ("IP / Trade Secret Leakage", 58, rgb("#f39c12")),
    ("Data Privacy Violation", 65, warn),
    ("Antitrust / Competition", 40, rgb("#2ecc71")),
    ("Force Majeure / Disruption", 30, ok),
  )
  for item in risks {
    let label = item.at(0)
    let score = item.at(1)
    let colour = item.at(2)
    grid(
      columns: (8em, 1fr, 3em),
      column-gutter: 6pt,
      align(right)[#text(8pt)[#label]],
      box(width: 100%, height: 14pt, fill: pale, radius: 3pt)[
        #box(width: score * 1%, height: 14pt, fill: colour, radius: 3pt)[
          #align(center + horizon)[#text(7pt, fill: white, weight: "bold")[]]
        ]
      ],
      align(left + horizon)[#text(8pt, weight: "bold")[#str(score)%]],
    )
    v(3pt)
  }
}

#v(0.8em)

// ── Financial Exposure Table ────────────────────────────────
== Financial Exposure Summary

#vars.at("text8", default: [Quantified risk exposure is modelled under three scenarios — baseline, adverse, and severe — reflecting varying degrees of contractual deviation, regulatory penalty, and litigation cost.])

#v(0.4em)

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 1fr),
  inset: 6pt,
  fill: (col, row) => if row == 0 { navy } else if calc.rem(row, 2) == 0 { pale },
  table.header(
    text(fill: white, weight: "bold")[Category],
    text(fill: white, weight: "bold")[Baseline],
    text(fill: white, weight: "bold")[Adverse],
    text(fill: white, weight: "bold")[Severe],
    text(fill: white, weight: "bold")[Provision],
  ),
  [Regulatory Penalties],     [\$120K],  [\$480K],   [\$1.2M],  [\$600K],
  [Litigation & Defense],     [\$85K],   [\$320K],   [\$900K],  [\$400K],
  [Settlement / Damages],     [\$200K],  [\$750K],   [\$2.5M],  [\$1.0M],
  [Operational Disruption],   [\$50K],   [\$180K],   [\$500K],  [\$200K],
  [Reputational / Goodwill],  [\$—],     [\$100K],   [\$350K],  [\$100K],
  [*TOTAL*],                  [*\$455K*],[*\$1.83M*],[*\$5.45M*],[*\$2.3M*],
)

// ══════════════════════════════════════════════════════════════
//  PAGE 2 — DETAILED LEGAL ANALYSIS & GRAPHS
// ══════════════════════════════════════════════════════════════
#pagebreak()

= Statutory & Regulatory Analysis

== Compliance Framework

#vars.at("text9", default: [The transaction is subject to the Securities Exchange Act of 1934 §10(b), the Dodd-Frank Wall Street Reform and Consumer Protection Act Title VII, and applicable state blue sky laws. Additionally, General Data Protection Regulation (GDPR) Articles 44–49 govern the cross-border data transfer components. The parties must ensure compliance with the Foreign Corrupt Practices Act (FCPA) §78dd-1 and UK Bribery Act 2010 §§6–7 in all jurisdictions where operations are conducted.])

#v(0.4em)

The regulatory landscape presents a multi-layered compliance challenge. Federal securities regulations impose strict liability for material misstatements and omissions, while state-level consumer protection statutes provide for treble damages in cases of willful violation. The intersection of domestic and international regulatory frameworks necessitates a coordinated compliance programme spanning no fewer than four distinct jurisdictional regimes.

#v(0.8em)

// ── Donut / pie-style chart — liability distribution ────────
== Liability Distribution Graph

#v(0.4em)

#{
  // Stacked area-style distribution using boxes
  let segments = (
    ("Contractual", 35, accent),
    ("Statutory", 25, rgb("#8e44ad")),
    ("Regulatory", 20, warn),
    ("Tortious", 12, rgb("#e67e22")),
    ("Equitable", 8, ok),
  )

  // Ring chart approximation with nested centred boxes
  align(center)[
    #box(width: 100%, inset: 8pt, radius: 6pt, fill: pale, stroke: 0.5pt + muted)[
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 12pt,
        [
          #text(9pt, weight: "bold", fill: navy)[Proportional Liability Allocation]
          #v(6pt)
          #{
            for item in segments {
              let label = item.at(0)
              let pct = item.at(1)
              let colour = item.at(2)
              grid(
                columns: (12pt, 6em, 1fr, 3em),
                column-gutter: 4pt,
                box(width: 10pt, height: 10pt, fill: colour, radius: 2pt)[],
                text(8pt)[#label],
                box(width: 100%, height: 10pt, fill: rgb("#e0e0e0"), radius: 2pt)[
                  #box(width: pct * 1%, height: 10pt, fill: colour, radius: 2pt)[]
                ],
                text(8pt, weight: "bold")[#str(pct)%],
              )
              v(4pt)
            }
          }
        ],
        [
          #text(9pt, weight: "bold", fill: navy)[Scenario Cost Trend (\$K)]
          #v(6pt)
          // Line-graph approximation using stepped bars
          #{
            let quarters = ("Q1", "Q2", "Q3", "Q4")
            let baseline = (110, 125, 140, 130)
            let adverse  = (210, 350, 420, 480)
            let severe   = (380, 620, 900, 1100)
            let max_val  = 1100

            for q in range(4) {
              text(7pt, fill: muted)[#quarters.at(q)]
              v(1pt)
              // Baseline bar
              grid(
                columns: (4em, 1fr),
                column-gutter: 4pt,
                text(7pt, fill: accent)[Base],
                box(width: baseline.at(q) / max_val * 100%, height: 8pt, fill: accent, radius: 2pt)[],
              )
              v(1pt)
              grid(
                columns: (4em, 1fr),
                column-gutter: 4pt,
                text(7pt, fill: rgb("#e67e22"))[Adv],
                box(width: adverse.at(q) / max_val * 100%, height: 8pt, fill: rgb("#e67e22"), radius: 2pt)[],
              )
              v(1pt)
              grid(
                columns: (4em, 1fr),
                column-gutter: 4pt,
                text(7pt, fill: warn)[Sev],
                box(width: severe.at(q) / max_val * 100%, height: 8pt, fill: warn, radius: 2pt)[],
              )
              v(6pt)
            }
          }
        ],
      )
    ]
  ]
}

#v(0.8em)

== Precedential Analysis

The following precedents are directly applicable to the matters under consideration:

+ _Ashcroft v. Iqbal_, 556 U.S. 662 (2009) — establishes the plausibility standard for pleading sufficiency, directly impacting the counterparty's ability to survive summary judgment on the breach claims.

+ _Chevron U.S.A., Inc. v. Natural Resources Defense Council_, 467 U.S. 837 (1984) — governs the deference framework for regulatory interpretation of the applicable agency rules.

+ _Texaco Inc. v. Pennzoil Co._, 729 S.W.2d 768 (Tex. App. 1987) — analogous tortious interference claim resulting in landmark damages, illustrative of maximum exposure.

+ _International Shoe Co. v. Washington_, 326 U.S. 310 (1945) — personal jurisdiction analysis for the multi-state enforcement scenario.

The cumulative weight of these authorities supports a conservative risk posture. Counsel recommends provisioning at the "adverse" scenario level pending resolution of the preliminary jurisdictional motions.

// ══════════════════════════════════════════════════════════════
//  PAGES 3–4 — CONDITIONAL REQUIREMENTS
// ══════════════════════════════════════════════════════════════
#pagebreak()

= Conditions & Requirements

== Conditions Precedent

The following conditions must be satisfied or waived in writing before the obligations of either party become binding. Failure to satisfy any condition by the Long-Stop Date shall entitle the non-defaulting party to terminate this agreement without liability.

#v(0.4em)

#vars.at("text10", default: [
  (a) Receipt of all requisite regulatory approvals, including but not limited to antitrust clearance under the Hart-Scott-Rodino Act and CFIUS review under the Foreign Investment Risk Review Modernization Act (FIRRMA).

  (b) Completion of satisfactory due diligence covering financial statements for the three most recent fiscal years, audited in accordance with GAAP, and verification of all material contracts, litigation disclosures, and intellectual property registrations.

  (c) Execution of all ancillary agreements, including the Transition Services Agreement, Intellectual Property License Agreement, Employee Transfer Agreement, and Escrow Agreement.

  (d) Delivery of legal opinions from counsel to each party, in form and substance reasonably satisfactory to the other party, confirming enforceability and no conflict with existing obligations.

  (e) No material adverse change shall have occurred between the date of this agreement and the closing date as defined in Schedule 2.1.
])

#v(0.6em)

// Conditions checklist table
#table(
  columns: (auto, 3fr, 1fr, 1fr),
  inset: 6pt,
  fill: (col, row) => if row == 0 { navy } else if calc.rem(row, 2) == 0 { pale },
  table.header(
    text(fill: white, weight: "bold")[Item],
    text(fill: white, weight: "bold")[Condition],
    text(fill: white, weight: "bold")[Status],
    text(fill: white, weight: "bold")[Deadline],
  ),
  [CP-1], [Regulatory Approval (HSR)],        [Pending],   [+60 days],
  [CP-2], [CFIUS / National Security Review],  [Pending],   [+90 days],
  [CP-3], [Financial Due Diligence],           [In Review], [+45 days],
  [CP-4], [Legal Due Diligence],               [In Review], [+45 days],
  [CP-5], [IP Portfolio Verification],         [Complete],  [Done],
  [CP-6], [Ancillary Agreements Execution],    [Draft],     [+30 days],
  [CP-7], [Third-Party Consents],              [Pending],   [+60 days],
  [CP-8], [Legal Opinions Delivered],          [Not Started],[+75 days],
  [CP-9], [No MAC Certification],              [Ongoing],   [Closing],
  [CP-10],[Board / Shareholder Approvals],     [Scheduled], [+20 days],
)

#v(0.8em)

== Conditions Subsequent & Termination Triggers

Notwithstanding the completion of closing, the following conditions subsequent shall apply for a period of twenty-four (24) months from the effective date (the "Monitoring Period"). Breach of any condition subsequent shall trigger the remedies set forth in Article VII, including but not limited to liquidated damages, clawback of consideration, and injunctive relief.

#v(0.4em)

#vars.at("text11", default: [
  (i) The acquired entity shall maintain a minimum current ratio of 1.5:1 and a maximum debt-to-equity ratio of 2.0:1, tested quarterly using the methodology prescribed in Schedule 4.3.

  (ii) Key personnel identified in Schedule 5.1 shall remain employed for a minimum of eighteen (18) months post-closing, subject to ordinary course termination exceptions and the non-compete provisions of the Employee Transfer Agreement.

  (iii) No regulatory action, enforcement proceeding, or investigation shall be commenced against the acquired entity that would reasonably be expected to result in penalties exceeding \$500,000 individually or \$1,500,000 in the aggregate.

  (iv) The acquired entity shall maintain all material licenses, permits, and authorisations in full force and effect, and shall not make any material change to its business operations without prior written consent (not to be unreasonably withheld).

  (v) Quarterly compliance reports shall be delivered to the monitoring committee within thirty (30) days of each fiscal quarter-end, in the format prescribed by Exhibit C.
])

#pagebreak()

// ── Page 4: Additional provisions, signature, notes ─────────
== Remedies & Enforcement

In the event of a breach of any condition subsequent during the Monitoring Period, the non-breaching party shall be entitled, at its election and without prejudice to any other remedies available at law or in equity, to the following:

#v(0.3em)

#box(inset: 10pt, fill: pale, radius: 4pt, width: 100%)[
  *Liquidated Damages:* A sum equal to 15% of the aggregate consideration, payable within thirty (30) business days of written demand, without requirement of proof of actual damages. The parties acknowledge that this sum represents a genuine pre-estimate of loss and is not a penalty.

  #v(4pt)
  *Clawback Mechanism:* The escrow agent shall release to the non-breaching party the lesser of (a) the amount of direct damages demonstrated and (b) the full escrow balance, upon certification by independent counsel that a qualifying breach has occurred.

  #v(4pt)
  *Injunctive Relief:* The parties acknowledge that monetary damages would be inadequate for breach of the confidentiality, non-compete, and non-solicitation provisions, and consent to the jurisdiction of the courts of the governing law state for injunctive and specific performance remedies.
]

#v(0.8em)

== Risk Mitigation Timeline

#{
  let milestones = (
    ("Month 1–2",  "Establish monitoring committee; baseline compliance audit", 15),
    ("Month 3–4",  "First quarterly review; regulatory filing confirmations", 35),
    ("Month 5–8",  "Integration milestones; IP transfer completion", 55),
    ("Month 9–12", "Mid-term review; financial covenant testing", 70),
    ("Month 13–18","Key personnel retention checkpoint; licence renewals", 85),
    ("Month 19–24","Final monitoring period; wind-down of escrow", 100),
  )

  for item in milestones {
    let period = item.at(0)
    let desc = item.at(1)
    let progress = item.at(2)
    grid(
      columns: (7em, 1fr, 4em),
      column-gutter: 6pt,
      text(8pt, weight: "bold", fill: navy)[#period],
      stack(dir: ttb,
        text(8pt)[#desc],
        v(2pt),
        box(width: 100%, height: 8pt, fill: rgb("#e0e0e0"), radius: 3pt)[
          #box(width: progress * 1%, height: 8pt, fill: accent, radius: 3pt)[]
        ],
      ),
      text(8pt, weight: "bold")[#str(progress)%],
    )
    v(6pt)
  }
}

#v(0.8em)

== Additional Provisions & Special Notes

#vars.at("text12", default: [No additional provisions have been specified. This section is reserved for bespoke terms, carve-outs, side letters, or other special arrangements that do not fit within the standard framework of this agreement. Any provisions added here shall be deemed incorporated by reference into the main body of the agreement and shall have equal force and effect.])

#v(1em)

// ── Signature block ─────────────────────────────────────────
#line(length: 100%, stroke: 0.5pt + muted)
#v(0.4em)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 40pt,
  [
    #v(1.5em)
    #line(length: 80%, stroke: 0.5pt + black)
    #v(2pt)
    #text(8pt)[Authorised Signatory — #vars.at("text3", default: "Party A")]
    #v(4pt)
    #text(8pt, fill: muted)[Date: \_\_\_\_\_\_\_\_\_\_\_\_]
  ],
  [
    #v(1.5em)
    #line(length: 80%, stroke: 0.5pt + black)
    #v(2pt)
    #text(8pt)[Authorised Signatory — #vars.at("text4", default: "Party B")]
    #v(4pt)
    #text(8pt, fill: muted)[Date: \_\_\_\_\_\_\_\_\_\_\_\_]
  ],
)

#v(0.6em)
#align(center)[
  #text(7pt, fill: muted)[
    PRIVILEGED & CONFIDENTIAL — ATTORNEY–CLIENT WORK PRODUCT \
    #vars.name | #vars.at("text5", default: "CASE-2024-00001") | Generated #vars.date
  ]
]
