@deprecate QuantileMM() Quantile(OMAS())
@deprecate QuantileMSPI() Quantile(MSPI())
@deprecate QuantileSGD() Quantile(SGD())

@deprecate QuantileMM(τ) Quantile(τ, OMAS())
@deprecate QuantileMSPI(τ) Quantile(τ, MSPI())
@deprecate QuantileSGD(τ) Quantile(τ, SGD())

"Deprecated.  See [`Quantile`](@ref)"
:QuantileSGD

"Deprecated.  See [`Quantile`](@ref)"
:QuantileMM

"Deprecated.  See [`Quantile`](@ref)"
:QuantileMSPI