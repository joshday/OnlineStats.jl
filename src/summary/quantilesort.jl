#-------------------------------------------------------# Type and Constructors
"""
QuantileSort takes the means of order statistics for samples of size 101.
The idea is that the 51st order statistic is unbiased(?) for the median since it
has half of the values above it and half of the values below it.

This needs some theoretical justification.
"""
type QuantileSort <: OnlineStat
    vals::VecF
    means::Means
    n::Int
end

QuantileSort() = QuantileSort(zeros(101), Means(101), 0)

function QuantileSort(y::VecF)
    o = QuantileSort()
    update!(o, y)
    o
end

function update!(o::QuantileSort, y::Float64)
    ind = (nobs(o) % 101) + 1
    o.vals[ind] = y
    o.n += 1
    if ind == 101
        update!(o.means, sort(o.vals))
    end
    return
end

#-----------------------------------------------------------------------# state
statenames(o::QuantileSort) = [:quantiles, :nobs]
state(o::QuantileSort) = Any[mean(o.means)[50], nobs(o)]
Base.quantile(o::QuantileSort, q::Int) = mean(o.means)[q + 1]
