using Weave

dir = Pkg.dir("OnlineStats", "doc", "examples")

examples = (
#     "/OnlineLinearModel.jmd",
#     "/OnlineFitBernoulli.jmd",
#     "/OnlineFitBeta.jmd",
#     "/Summary.jmd",
#     "/QuantileSGD.jmd",
#     "/QuantileMM.jmd",
#     "/quantilecompare.jmd",
#     "/CovarianceMatrix.jmd",
#     "/FiveNumberSummary.jmd",
#     "/Moments.jmd",
#     "/QuantRegSGD.jmd",
#     "/QuantRegMM.jmd",
#     "/quantregcompare.jmd",
    "/NormalMix.jmd",
    "/LogRegMM.jmd",
    "/LogRegSGD.jmd",
#     "/RidgeReg.jmd"
    )


for i in examples
    weave(dir * i, doctype="github", informat="markdown")
end
