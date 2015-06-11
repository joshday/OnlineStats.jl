#-----------------------------------------# generic: nobs, update!, copy, merge

nobs(o::OnlineStat) = o.n

update!{T<:Real}(o::OnlineStat, y::Vector{T}) = (for yi in y; update!(o, yi); end)

Base.copy(o::OnlineStat) = deepcopy(o)

function Base.merge(o1::OnlineStat, o2::OnlineStat)
    o1copy = copy(o1)
    merge!(o1copy, o2)
    o1copy
end



row(M::MatF, i::Int) = vec(M[i,:])
col(M::MatF, i::Int) = M[:,i]
row!(M::MatF, i::Int, v::VecF) = (M[i,:] = v)
col!(M::MatF, i::Int, v::VecF) = (M[:,i] = v)


#------------------------------------------------------------------------# Show
# temporary fix for the "how to print" problem... lets come up with something nicer
mystring(f::Float64) = @sprintf("%f", f)
mystring(x) = string(x)


name(o::OnlineStat) = string(typeof(o))


function Base.print{T<:OnlineStat}(io::IO, v::Vector{T})
    print(io, "[")
    print(io, join(v, ", "))
    print(io, "]")
end

function Base.print(io::IO, o::OnlineStat)
    snames = statenames(o)
    svals = state(o)
    print(io, name(o), "{")
    for (i,sname) in enumerate(snames)
        print(io, i > 1 ? " " : "", sname, "=", svals[i])
    end
    print(io, "}")
end

function Base.show(io::IO, o::OnlineStat)
    snames = statenames(o)
    svals = state(o)

    println(io, "Online ", name(o))
    for (i, sname) in enumerate(snames)
        println(io, @sprintf(" * %8s:  %s\n", sname, mystring(svals[i])))
    end
end


#------------------------------------------------------------------------# DataFrame
function DataFrame(o::OnlineStat; addFirstRow::Bool = true)
    s = state(o)
    df = DataFrame(map(typeof, s), statenames(o), 0)
    if addFirstRow
        push!(df, s)
    end
    df
end

Base.push!(df::DataFrame, o::OnlineStat) = push!(df, state(o))


# some nice helper functions to extract stuff from dataframes...
# this might exist already in dataframes... didn't look too hard

function getnice(df::DataFrame, s::Symbol)
    data = df[s]
    makenice(data)
end

makenice{T<:Vector}(da::DataArray{T}) = hcat(da...)'
makenice{T<:Number}(da::DataArray{T}) = convert(Array, da)



#------------------------------------------------------------# DistributionStat
function Base.show(io::IO, o::DistributionStat)
    println("Online " * string(typeof(o)) * ", nobs:" * string(nobs(o)))
    show(o.d)
end

statenames(o::DistributionStat) = [:dist, :nobs]
state(o::DistributionStat) = [o.d, o.n]

params(o::DistributionStat) = params(o.d)
succprob(o::DistributionStat) = succprob(o.d)
failprob(o::DistributionStat) = failprob(o.d)
scale(o::DistributionStat) = scale(o.d)
# location(o::DistributionStat) = location(o.d)  # doesn't apply to any distribution yet
shape(o::DistributionStat) = shape(o.d)
rate(o::DistributionStat) = rate(o.d)
ncategories(o::DistributionStat) = ncategories(o.d)
ntrials(o::DistributionStat) = ntrials(o.d)
# dof(o::DistributionStat) = dof(o.d)  # doesn't apply to any distribution yet

mean(o::DistributionStat) = mean(o.d)
var(o::DistributionStat) = var(o.d)
std(o::DistributionStat) = std(o.d)
median(o::DistributionStat) = median(o.d)
mode(o::DistributionStat) = mode(o.d)
modes(o::DistributionStat) = modes(o.d)
skewness(o::DistributionStat) = skewness(o.d)
kurtosis(o::DistributionStat) = kurtosis(o.d)
isplatykurtic(o::DistributionStat) = isplatykurtic(o.d)
ismesokurtic(o::DistributionStat) = ismesokurtic(o.d)
entropy(o::DistributionStat) = entropy(o.d)

mgf(o::DistributionStat, x) = mgf(o.d, x)
cf(o::DistributionStat, x) = cf(o.d, x)
insupport(o::DistributionStat, x) = insupport(o.d, x)
pdf(o::DistributionStat, x) = pdf(o.d, x)
logpdf(o::DistributionStat, x) = logpdf(o.d, x)
StatsBase.loglikelihood(o::DistributionStat, x) = Distributions.loglikelihood(o.d, x)
cdf(o::DistributionStat, x) = cdf(o.d, x)
logcdf(o::DistributionStat, x) = logcdf(o.d, x)
ccdf(o::DistributionStat, x) = ccdf(o.d, x)
logccdf(o::DistributionStat, x) = logccdf(o.d, x)
quantile(o::DistributionStat, τ) = quantile(o.d, τ)
cquantile(o::DistributionStat, τ) = cquantile(o.d, τ)
invlogcdf(o::DistributionStat, x) = invlogcdf(o.d, x)
invlogccdf(o::DistributionStat, x) = invlogccdf(o.d, x)

rand(o::DistributionStat) = rand(o.d)
rand(o::DistributionStat, n_or_dims) = rand(o.d, n_or_dims)
rand!(o::DistributionStat, arr) = rand!(o.d, arr)

