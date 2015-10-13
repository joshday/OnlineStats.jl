#-----------------------------------------# generic: nobs, update!, copy, merge
"The number of observations"
nobs(o::OnlineStat) = o.n


"""
`update!(o, data...)`

`update!(o, data...; b = batchsize)`

Update an OnlineStat with `data`.  If `b` is specified, the OnlineStat
will be updated in batches of size `b`.
"""
function update!(o::OnlineStat, y::Union{AVec, AMat}, b::Integer = size(y, 1))
    b = @compat Int(b)
    n = size(y, 1)
    if b < n
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            updatebatch!(o, rows(y, rng))
            i += b
        end
    else
        for i in 1:n
            update!(o, row(y, i))
        end
    end
end

# Statistical Model update
function update!(o::OnlineStat, x::AMat, y::AVec, b::Integer = length(y))
    b = @compat Int(b)
    n = length(y)
    if b < n
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            updatebatch!(o, rows(x, rng), rows(y, rng))
            i += b
        end
    else
        for i in 1:n
            update!(o, row(x, i), y[i])
        end
    end
end

# If an OnlineStat doesn't have an updatebatch method, update
updatebatch!(o::OnlineStat, data...) = update!(o, data...)

"""
`tracefit!(o, b, data...; batch = false)`

Run through data as in `distributionfit!`.  Return a vector of OnlineStats where each
element has been updated with a batch of size `b`.
"""
function tracefit!(o::OnlineStat, b::Integer, data...; batch::Bool = false)
    b = @compat Int(b)
    n = nrows(data[1])
    i = 1
    s = state(o)
    result = [copy(o)]
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_data = map(x -> rows(x, rng), data)
        batch ? updatebatch!(o, batch_data...) : update!(o, batch_data...)
        push!(result, copy(o))
        i += b
    end
    result
end


Base.copy(o::OnlineStat) = deepcopy(o)

function Base.merge(o1::OnlineStat, o2::OnlineStat)
    o1copy = copy(o1)
    merge!(o1copy, o2)
    o1copy
end

function Base.(:(==)){T<:OnlineStat}(o1::T, o2::T)
    @compat for field in fieldnames(o1)
        getfield(o1, field) == getfield(o2, field) || return false
    end
    true
end


row(x::AMat, i::Integer) = rowvec_view(x, i)
col(x::AMat, i::Integer) = view(x, :, i)
row!{T}(x::AMat{T}, i::Integer, v::AVec{T}) = (x[i,:] = v)
col!{T}(x::AMat{T}, i::Integer, v::AVec{T}) = (x[:,i] = v)
row(x::AVec, i::Integer) = x[i]

rows(x::AVec, rs::AVec{Int}) = view(x, rs)
rows(x::AMat, rs::AVec{Int}) = view(x, rs, :)
cols(x::AMat, cs::AVec{Int}) = view(x, :, cs)

rows(x::AbstractArray, i::Integer) = row(x,i)
cols(x::AbstractArray, i::Integer) = col(x,i)

nrows(M::AbstractArray) = size(M,1)
ncols(M::AbstractArray) = size(M,2)


#------------------------------------------------------------------------# Show

# TODO: use my "fmt" method in Formatting.jl if/when the PR is merged
# temporary fix for the "how to print" problem... lets come up with something nicer
mystring(f::AbstractFloat) = @sprintf("%f", f)
mystring(x) = string(x)


name(o::OnlineStat) = string(typeof(o))


function Base.print{T<:OnlineStat}(io::IO, v::AVec{T})
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
    print(io, "OnlineStat: ", name(o))
    for (i, sname) in enumerate(snames)
        print(io, @sprintf("\n * %8s:  %s", sname, mystring(svals[i])))
    end
end
