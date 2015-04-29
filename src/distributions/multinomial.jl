export FitMultinomial

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type FitMultinomial <: OnlineMultivariateDistribution
    d::Distributions.Multinomial
    means::Vector{Float64}
    n::Int64
end

function onlinefit(::Type{Multinomial}, x::Matrix)
    n::Int64 = size(x, 2)
    FitMultinomial(fit(Multinomial, x), vec(mean(x, 2)), n)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::FitMultinomial, x::Matrix)
    p, n = size(x)
    obj.n += n
    obj.means += (n / obj.n) * (vec(mean(x, 2)) - obj.means)
    obj.d = Multinomial(obj.d.n, obj.means / obj.d.n)
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
function state(obj::FitMultinomial)
    DataFrame(variable = [:n; [symbol("p$i") for i in 1:length(obj.d.p)]],
              value = [obj.d.n; obj.d.p],
              nobs = nobs(obj))
end

Base.copy(obj::FitMultinomial) = FitMultinomial(obj.d, obj.means, obj.n)
