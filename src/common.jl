#-----------------------------------------# generic: nobs, update!, copy, merge

doc"The number of observations"
nobs(o::OnlineStat) = o.n

doc"Update an OnlineStat one data point at a time"
function update!{T<:Real}(o::OnlineStat, y::AVec{T})
    for yi in y
        update!(o, yi)
    end
end

function update!{T<:Real}(o::OnlineStat, x::AMat{T}, y::AVec{T})
    @inbounds for i in 1:length(y)
        update!(o, row(x,i), y[i])
    end
end


# getrows(x::Vector, rows) = x[rows]
# getrows(x::Matrix, rows) = x[rows, :]

# Fit the data using batch size b
# defaults to update!() for batch = false)
function onlinefit!(o::OnlineStat, b::Integer, args...; batch::Bool = false)
    if !batch
        update!(o, args...)
    else
        n = size(args[1],1)
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            batch_args = map(x -> rows(x,rng), args)
            updatebatch!(o, batch_args...)
            i += b
        end
    end
end
# Create a vector of OnlineStats, each element is updated with a batch of size b
function tracefit!(o::OnlineStat, b::Integer, args...; batch::Bool = false)
    n = nrows(args[1])
    i = 1
    s = state(o)
    result = [copy(o)]
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_args = map(x -> rows(x, rng), args)
        batch ? updatebatch!(o, batch_args...) : update!(o, batch_args...)
        push!(result, copy(o))  #result = vcat(result, state(o)')
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



row(M::AMatF, i::Integer) = rowvec_view(M, i)
col(M::AMatF, i::Integer) = view(M, :, i)
row!(M::AMatF, i::Integer, v::AVecF) = (M[i,:] = v)
col!(M::AMatF, i::Integer, v::AVecF) = (M[:,i] = v)

rows(x::AVec, rs::AVec{Int}) = view(x, rs)
rows(x::AMat, rs::AVec{Int}) = view(x, rs, :)
cols(x::AMat, cs::AVec{Int}) = view(x, :, cs)

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
