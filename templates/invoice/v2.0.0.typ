#let vars = json.decode(sys.inputs.at("data", default: "{}"))

#set page(paper: "a4", margin: (x: 2cm, y: 2.5cm))
#set text(size: 11pt)
#set par(justify: true)

= #vars.name

*Date:* #vars.date

#vars.at("text1", default: "")
