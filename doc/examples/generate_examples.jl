using Weave

dir = Pkg.dir("OnlineStats", "doc", "examples")

examples = (
    "/OnlineLinearModel.jmd",
    "/OnlineFitBeta.jmd",
    "/Summary.jmd",
    "/QuantileSGD.jmd",
    "/QuantileMM.jmd"
    )



for i in examples
    weave(dir * i, doctype="github", informat="markdown")
end
