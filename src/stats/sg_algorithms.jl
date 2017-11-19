abstract type Updater end

abstract type SGUpdater <: Updater end

Base.show(io::IO, u::Updater) = print(io, name(u))
Base.merge!(o::T, o2::T, γ::Float64) where {T <: Updater} = warn("$T can't be merged.")


#-----------------------------------------------------------------------# SGD
struct SGD <: SGUpdater end
Base.merge!(a::SGD, b::SGD, γ::Float64) = a

#-----------------------------------------------------------------------# MSPI
mutable struct MSPI{T} <: SGUpdater
    buffer::T 
end
MSPI() = MSPI(nothing)
function Base.merge!(a::MSPI{T}, b::MSPI{T}, γ::Float64) where {T} 
    smooth!.(a.buffer, b.buffer, γ)
    a
end