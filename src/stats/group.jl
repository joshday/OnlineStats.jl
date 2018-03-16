#-----------------------------------------------------------------------# Group
"""
    Group(stats::OnlineStat{0}...)
    Group(tuple)

Create a vector-input stat (`OnlineStat{1}`) from several scalar-input stats.  For a new 
observation `y`, `y[i]` is sent to `stats[i]`.

# Examples

    fit!(Group(Mean(), Mean()), randn(100, 2))
    fit!(Group(Mean(), Variance()), randn(100, 2))
"""
struct Group{T} <: OnlineStat{1}
    stats::T
end
Group(o::OnlineStat{0}...) = Group(o)
nobs(o::Group) = nobs(first(o.stats))

@generated function _fit!(o::Group{T}, y) where {T}
    N = length(fieldnames(T))
    :(Base.Cartesian.@nexprs $N i -> @inbounds(_fit!(o.stats[i], y[i])))
end

Base.:*(n::Integer, o::OnlineStat{0}) = Group([copy(o) for i in 1:n]...)
