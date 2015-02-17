using Weave

weave(Pkg.dir("OnlineStats", "doc", "example", "summary_example.jmd"),
      doctype="pandoc")
