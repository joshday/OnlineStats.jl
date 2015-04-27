#-------------------------------------------------------# Type and Constructors
type FiveNumberSummary <: ScalarOnlineStat
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


#-------------------------------------------------------------# param and value
param(obj::FiveNumberSummary) = [:min, :q1, :median, :q3, :max]

value(obj::FiveNumberSummary) = [obj.min; copy(obj.quantile.est); obj.max]


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


#----------------------------------------------------------------------# Base
Base.copy(obj::FiveNumberSummary) = FiveNumberSummary(obj.min, obj.quantile,
                                                      obj.max, obj.n, obj.nb)
