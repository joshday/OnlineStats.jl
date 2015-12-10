"""
QuantileSort

Experimental biased quantiles
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
statenames(o::QuantileSort) = [:median, :nobs]
state(o::QuantileSort) = Any[mean(o.means)[50], nobs(o)]

"Get quantile `q/100`"
Base.quantile(o::QuantileSort, q::Int) = mean(o.means)[q + 1]
