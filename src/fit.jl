#------------------------------------------------------------------------------# fit!
# There are so many fit methods because
#    - Each method needs two implementations (ScalarInput, VectorInput)
#    - methods:
#        - singleton
#        - batch
#        - singleton + float
#        - batch + float
#        - batch + vector of floats
#        - batch + integer
"""
Update an OnlineStat with more data.  Additional arguments after the input data
provide extra control over how the updates are done.

```
y = randn(100)
o = Mean()

fit!(o, y)      # standard usage

fit!(o, y, 10)  # update in minibatches of size 10

fit!(o, y, .1)  # update using weight .1 for each observation

wts = rand(100)
fit!(o, y, wts) # update observation i using wts[i]
```
"""
#---------------------------------------------------------------------------# ScalarInput
function fit!(o::OnlineStat{ScalarInput}, y::Real)
    updatecounter!(o)
    γ = weight(o)
    _fit!(o, y, γ)
    o
end
function fit!(o::OnlineStat{ScalarInput}, y::Real, γ::Float64)
    updatecounter!(o)
    _fit!(o, y, γ)
    o
end
function fit!(o::OnlineStat{ScalarInput}, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end
function fit!(o::OnlineStat{ScalarInput}, y::AVec, w::Real)
    for i in eachindex(y)
        @inbounds fit!(o, y[i], w)
    end
    o
end
function fit!(o::OnlineStat{ScalarInput}, y::AVec, w::AVec)
    @assert length(y) == length(w)
    for i in eachindex(y)
        @inbounds fit!(o, row(y, i), w[i])
    end
    o
end
function fit!(o::OnlineStat{ScalarInput}, y::AVec, b::Integer)
    b = Int(b)
    n = length(y)
    0 < b <= n || warn("batch size larger than data size")
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            bsize = length(rng)
            updatecounter!(o, bsize)
            γ = weight(o, bsize)
            _fitbatch!(o, rows(y, rng), γ)
            i += b
        end
    end
    o
end

#---------------------------------------------------------------------------# VectorInput
function fit!{T <: Real}(o::OnlineStat{VectorInput}, y::AVec{T})
    updatecounter!(o)
    γ = weight(o)
    _fit!(o, y, γ)
    o
end
function fit!{T <: Real}(o::OnlineStat{VectorInput}, y::AVec{T}, γ::Float64)
    updatecounter!(o)
    _fit!(o, y, γ)
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat)
    for i in 1:size(y, 1)
        fit!(o, row(y, i))
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat, w::Real)
    n2 = nrows(y)
    for i in 1:n2
        fit!(o, row(y, i), w)
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat, w::AVec)
    n2 = nrows(y)
    @assert n2 == length(w)
    for i in 1:n2
        @inbounds fit!(o, row(y, i), w[i])
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat, b::Integer)
    b = Int(b)
    n = size(y, 1)
    0 < b <= n || warn("batch size larger than data size")
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            bsize = length(rng)
            updatecounter!(o, bsize)
            γ = weight(o, bsize)
            _fitbatch!(o, rows(y, rng), γ)
            i += b
        end
    end
    o
end


# warning if no fitbatch! method
_fitbatch!(o, args...) = (warn("no fitbatch! method...calling fit!"); _fit!(o, args...))
