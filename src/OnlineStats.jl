module OnlineStats

using Docile
@document

using DataFrames, Distributions
import PDMats, Distributions
import Base: copy, merge, merge!, show, quantile
import StatsBase: nobs, vcov, coef, confint, coeftable, predict, fit, fit!

export update!, state, addstate!, onlinefit, nobs

#-----------------------------------------------------------------------------#
# Source files
#-----------------------------------------------------------------------------#
# Abstract Types
include("types.jl")

# Other
include("trace.jl")

# Summary Statistics
include("summary/mean.jl")
include("summary/var.jl")
include("summary/extrema.jl")
include("summary/summary.jl")
include("summary/covmatrix.jl")
include("summary/moments.jl")
include("summary/quantilesgd.jl")
include("summary/quantilemm.jl")
include("summary/fivenumber.jl")

# Parametric Density
# include("parametricdensity/bernoulli.jl")
# include("parametricdensity/beta.jl")
# include("parametricdensity/binomial.jl")
# include("parametricdensity/dirichlet.jl")
# include("parametricdensity/exponential.jl")
# include("parametricdensity/gamma.jl")
# include("parametricdensity/multinomial.jl")
# include("parametricdensity/mvnormal.jl")
# include("parametricdensity/normal.jl")

# Density Estimation
# include("densityestimation/offlinenormalmix.jl")
# include("densityestimation/normalmix.jl")

# Linear Model
# include("linearmodel/sweep.jl")
# include("linearmodel/linreg.jl")
# include("linearmodel/sparsereg.jl")
# include("linearmodel/ridge.jl")

# GLM
# include("glm/logisticregsgd.jl")
# include("glm/logisticregmm.jl")
# include("glm/logisticregsn.jl")

# Quantile Regression
include("quantileregression/quantregsgd.jl")
include("quantileregression/quantregmm.jl")



#-----------------------------------------------------------------------------#
# Functions for any OnlineStat type
#-----------------------------------------------------------------------------#
"Return the number of observations used"
nobs{T <: OnlineStat}(obj::T) = obj.n

"`addstate(df, obj)`: Add `state(obj)` results to a new row in `df`"
function addstate!{O <: OnlineStat}(df::DataFrame, obj::O)
    append!(df, state(obj))
end

#-----------------------------------------------------------------------------#
# Docstrings for functions
#-----------------------------------------------------------------------------#
"`state(obj)`: Return a DataFrame with the current estimate and nobs"
state

"`update!(obj, newdata)`: Use `newdata` to update estimates in `obj`"
update!

end # module
