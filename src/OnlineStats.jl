module OnlineStats

using Docile
@document
using DataFrames, Distributions, StatsBase
import PDMats, Distributions
import Base: copy, merge, merge!, show, quantile
import StatsBase: nobs, vcov, coef, confint, coeftable, predict, fit, fit!
# import Gadfly


export update!, state, onlinefit, nobs, make_df, make_df!

# Abstract Types
include("types.jl")

#-----------------------------------------------------------------------------#
# Functions for any OnlineStat type
#-----------------------------------------------------------------------------#
"Return the number of observations used"
nobs{T <: OnlineStat}(obj::T) = obj.n

@doc md"Put object results in a DataFrame" ->
function make_df{T <: OnlineStat}(obj::T)
    s = OnlineStats.state(obj)
    names::Vector{Symbol} = s[:, 1]
    df = convert(DataFrame, s[:, 2]')
    names!(df, names)
    return df
end

@doc md"Add the current state of `obj` to a new row in `df`" ->
function make_df!{T <: OnlineStat}(df::DataFrame, obj::T)
    push!(df, state(obj)[:, 2])
end


#-----------------------------------------------------------------------------#
# Functions for any OnlineStat type
#-----------------------------------------------------------------------------#
# Other
# include("trace.jl")

# Summary Statistics
include("summary/mean.jl")
include("summary/var.jl")
# include("summary/extrema.jl")
# include("summary/summary.jl")
include("summary/covmatrix.jl")
# include("summary/moments.jl")
# include("summary/quantilesgd.jl")
# include("summary/quantilemm.jl")
# include("summary/fivenumber.jl")

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
# include("quantileregression/quantregsgd.jl")
# include("quantileregression/quantregmm.jl")

end # module
