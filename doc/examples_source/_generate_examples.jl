using Weave

src = Pkg.dir("OnlineStats", "doc", "examples_source")
dst = Pkg.dir("OnlineStats", "doc")

examples = (
    "/LinReg.jmd",
    "/Summary.jmd",
    "/QuantileSGD.jmd",
    "/QuantileMM.jmd",
    "/quantilecompare.jmd",
    "/CovarianceMatrix.jmd",
    "/FiveNumberSummary.jmd",
    "/Moments.jmd",
    "/QuantRegSGD.jmd",
    "/QuantRegMM.jmd",
#     "/NormalMix.jmd",
#     "/LogRegMM.jmd",
#     "/LogRegSGD.jmd",
#     "/RidgeReg.jmd"
    )


for i in examples
    weave(src * i, doctype = "github", informat = "markdown",
          out_path = dst)
end
