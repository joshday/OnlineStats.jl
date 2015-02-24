using Weave

dir = Pkg.dir("OnlineStats", "doc", "examples")

weave(dir * "/OnlineLinearModel.jmd", doctype="github", informat="markdown")
weave(dir * "/OnlineFitBeta.jmd", doctype="github", informat="markdown")
