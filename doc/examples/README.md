# Generating markdown files

```julia
using Weave
weave(Pkg.dir("OnlineStats", "doc", "examples","OnlineLinearModel.jmd"), doctype="github",informat="markdown")
```