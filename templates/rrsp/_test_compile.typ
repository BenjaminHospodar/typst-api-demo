// Local compile using sidecar-compatible sys.inputs (not a pasted #let vars).
// From this directory:
//   typst compile --input data="$(cat fixture.json)" _test_compile.typ _test_compile.pdf
// PowerShell:
//   typst compile --input "data=$(Get-Content -Raw fixture.json)" _test_compile.typ _test_compile.pdf
#include "v1.0.0.typ"
