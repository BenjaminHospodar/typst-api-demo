#let vars = json.decode(sys.inputs.at("data", default: "{}"))

#set page(paper: "a4", margin: (x: 2cm, y: 2cm))
#set text(size: 10pt)
#set par(justify: true)

// ── Minimal fast template for TPS benchmarks ────────────────
= #vars.name

*Date:* #vars.date

#vars.at("text1", default: "Benchmark document for throughput testing.")
