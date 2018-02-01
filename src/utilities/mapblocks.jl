#-----------------------------------------------------------------------# mapblocks
"""
    mapblocks(f::Function, b::Int, data, dim::ObsDimension = Rows())

Map `data` in batches of size `b` to the function `f`.  If data includes an AbstractMatrix, the batches will be based on rows or columns, depending on `dim`.  Most usage is through Julia's `do` block syntax.

# Examples

    s = Series(Mean())
    mapblocks(10, randn(100)) do yi
        fit!(s, yi)
        info("nobs: \$(nobs(s))")
    end

    x = [1 2 3 4; 
         1 2 3 4; 
         1 2 3 4;
         1 2 3 4]
    mapblocks(println, 2, x)
    mapblocks(println, 2, x, Cols())
"""
function mapblocks(f::Function, b::Integer, y, dim::ObLoc = Rows())
    n = _nobs(y, dim)
    i = 1
    while i <= n
        rng = i:min(i + b - 1, n)
        yi = getblock(y, rng, dim)
        f(yi)
        i += b
    end
end

_nobs(y::VectorOb, ::ObLoc) = length(y)
_nobs(y::AbstractMatrix, ::Rows) = size(y, 1)
_nobs(y::AbstractMatrix, ::Cols) = size(y, 2)
function _nobs(y::Tuple{AbstractMatrix, VectorOb}, dim::ObLoc)
    n = _nobs(first(y), dim)
    if all(_nobs.(y, dim) .== n)
        return n
    else
        error("Data objects have different nobs")
    end
end


getblock(y::VectorOb, rng, ::ObLoc) = @view y[rng]
getblock(y::AbstractMatrix, rng, ::Rows) = @view y[rng, :]
getblock(y::AbstractMatrix, rng, ::Cols) = @view y[:, rng]
function getblock(y::Tuple{AbstractMatrix, VectorOb}, rng, dim::ObLoc)
    map(x -> getblock(x, rng, dim), y)
end