abstract type Updater end

abstract type SGUpdater <: Updater end

Base.show(io::IO, u::Updater) = print(io, name(u))
Base.merge!(o::T, o2::T, γ::Float64) where {T <: Updater} = warn("$T can't be merged.")


#-----------------------------------------------------------------------# SGD
struct SGD <: SGUpdater end
Base.merge!(a::SGD, b::SGD, γ::Float64) = a

#-----------------------------------------------------------------------# MSPI
for T in [:OMAS, :OMAS2, :OMAP, :OMAP2, :MSPI, :MSPI2]
    @eval begin
        """
            MSPI()  # Majorized stochastic proximal iteration
            MSPI2()
            OMAS()  # Online MM - Averaged Surrogate
            OMAS2()
            OMAP()  # Online MM - Averaged Parameter
            OMAP2()

        Updaters based on majorizing functions.  `MSPI`/`OMAS`/`OMAP` define a family of 
        algorithms and not a specific update, thus each type has two possible versions.

        - See https://arxiv.org/abs/1306.4650 for OMAS
        - Ask @joshday for details on OMAP and MSPI
        """
        struct $T{T} <: Updater
            buffer::T 
        end
        $T() = $T(nothing)
        function Base.merge!(a::$T{T}, b::$T{T}, γ::Float64) where {T} 
            smooth!.(a.buffer, b.buffer, γ)
            a
        end
    end 
end