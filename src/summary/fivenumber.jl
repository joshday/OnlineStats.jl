export FiveNumberSummary

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type FiveNumberSummary <: ContinuousUnivariateOnlineStat
    min::Float64
    quantile::QuantileSGD
    max::Float64
    n::Int64
    nb::Int64
end

function FiveNumberSummary(y::Vector; r = .7)
    FiveNumberSummary(minimum(y), QuantileSGD(y, r = r), maximum(y),
                      length(y), 1)
end

FiveNumberSummary(y::Real; r = .7) = FiveNumberSummary([y], r)


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::FiveNumberSummary, y::Vector)
    n2 = length(y)
    update!(obj.quantile, y)
    obj.min = minimum([obj.min, y])
    obj.max = maximum([obj.max, y])
    obj.n += n2
    obj.nb += 1
end

update(obj::FiveNumberSummary, x::Real) = update!(obj, [x])


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::FiveNumberSummary)
    names = [:min, :q25, :q50, :q75, :max, :n, :nb]
    estimates = [obj.min, obj.quantile.est, obj.max, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#--------------------------------------------------------------------# Boxplot
function state(obj::FiveNumberSummary)
    names = [:min, :q25, :q50, :q75, :max, :n, :nb]
    estimates = [obj.min, obj.quantile.est, obj.max, obj.n, obj.nb]
    return([names estimates])
end


# function Gadfly.plot(obj::FiveNumberSummary)
#     s = state(obj)[1:5, 2]
#     iqr = obj.quantile.est[3] - obj.quantile.est[1]
#    Gadfly.plot(lower_fence = [maximum((s[2] - 1.5 * iqr, s[1]))],
#                lower_hinge = [s[2]],
#                middle = [s[3]],
#                upper_hinge = [s[4]],
#                upper_fence = [minimum((s[4] + 1.5 * iqr, s[5]))],
#                # outliers = [s[1], s[5]],
#                x = ["Data"], Gadfly.Geom.boxplot)
# end



#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
Base.copy(obj::FiveNumberSummary) = FiveNumberSummary(obj.min, obj.quantile,
                                                      obj.max, obj.n, obj.nb)


function Base.merge(a::FiveNumberSummary, b::FiveNumberSummary)
    min = minimum([a.min, b.min])
    quantile = merge(a.quantile, b.quantile)
    max = maximum([a.max, b.max])
    n = a.n + b.n
    nb = a.nb + b.nb
    FiveNumberSummary(min, quantile, max, n, nb)
end

function Base.merge!(a::FiveNumberSummary, b::FiveNumberSummary)
    a.min = minimum([a.min, b.min])
    merge!(a.quantile, b.quantile)
    a.max = maximum([a.max, b.max])
    a.n += b.n
    a.nb += b.nb
end

function Base.show(io::IO, obj::FiveNumberSummary)
    @printf(io, "Online Five Number Summary\n")
    @printf(io, " * Min:    %f\n", obj.min)
    @printf(io, " * Q1:     %f\n", obj.quantile.est[1])
    @printf(io, " * Median: %f\n", obj.quantile.est[2])
    @printf(io, " * Q3:     %f\n", obj.quantile.est[3])
    @printf(io, " * Max:    %f\n", obj.max)
    @printf(io, " * N:      %d\n", obj.n)
    @printf(io, " * NB:     %d\n", obj.nb)
    return
end
