# Templates

One directory per form, one `.typ` file per version (`vMAJOR.MINOR.PATCH.typ`). Optional sibling `v*.schema.json` (`required` keys) and `fixture.json` for local CLI compiles.

## Binding

Every server template starts with:

```typ
#let vars = json.decode(sys.inputs.at("data", default: "{}"))
```

Do not `#import "@preview/..."`. The sidecar World has no package resolver. Fonts come from `typst-assets`; extra images from `TYPST_ASSETS_DIR`.

`_test_compile.typ` files are **not seeded**. Local compile:

```bash
cd templates/invoice
typst compile --input data="$(cat fixture.json)" _test_compile.typ
```

Seed into Postgres:

```bash
python scripts/seed_templates.py
```
