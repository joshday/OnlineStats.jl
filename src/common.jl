#-----------------------------------------# generic: nobs, update!, copy, merge

"The number of observations"
nobs(o::OnlineStat) = o.n

"""
`update!(o, data...)`

Update an OnlineStat one data point at a time
"""
function update!{T<:Real}(o::OnlineStat, x::AVec{T})
    for xi in x
        update!(o, xi)
    end
end

function update!{T<:Real}(o::OnlineStat, x::AMat{T})
  for i in 1:nrows(x)
      update!(o, row(x,i))
  end
end

function update!{T<:Real}(o::OnlineStat, x::AMat{T}, y::AVec{T})
    @inbounds for i in 1:length(y)
        update!(o, row(x,i), y[i])
    end
end

"""
`updatebatch!(o, data...)`

Update an OnlineStat with a batch of data.  The batch is treated as an equal piece of information.
"""
function updatebatch! end

"""
`onlinefit!(o, b, data...; batch = false)`

Update the OnlineStat `o` with `data` using batches of size `b`.  If `batch = false`,
this calls `update!(o, data...)`.  If `batch = true`, it calls `updatebatch!` for each batch.
"""
function onlinefit!(o::OnlineStat, b::Integer, data...; batch::Bool = false)
    if !batch
        update!(o, data...)
    else
        n = size(data[1],1)
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            batch_data = map(x -> rows(x,rng), data)
            updatebatch!(o, batch_data...)
            i += b
        end
    end
end

"""
`tracefit!(o, b, data...; batch = false)`

Run through data as in `distributionfit!`.  Return a vector of OnlineStats where each
element has been updated with a batch of size `b`.
"""
function tracefit!(o::OnlineStat, b::Integer, data...; batch::Bool = false)
    n = nrows(args[1])
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

function =={T<:OnlineStat}(o1::T, o2::T)
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
mystring(f::FloatingPoint) = @sprintf("%f", f)
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

    println(io, "Online ", name(o))
    for (i, sname) in enumerate(snames)
        println(io, @sprintf(" * %8s:  %s\n", sname, mystring(svals[i])))
    end
end
