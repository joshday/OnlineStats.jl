function name(o, withparams = true)
    s = replace(string(typeof(o)), "OnlineStats.", "")
    if !withparams
        s = replace(s, r"\{(.*)", "")
    end
    s
end

header(io::IO, s::AbstractString) = print_with_color(:light_cyan, io, "■ $s")

subheader(io::IO, s::AbstractString) = print_with_color(:light_cyan, io, "  ■ $s")

function print_item(io::IO, name::AbstractString, value, newline=true)
    print(io, "  >" * @sprintf("%15s", name * ": "), value)
    newline && println(io)
end

fields_to_show(o::OnlineStat) = fieldnames(o)

function printfields(io::IO, o, nms = fields_to_show(o))
    if length(nms) != 0
        s = "("
        for nm in nms
            s *= "$nm = $(getfield(o, nm))"
            if nms[end] != nm
                s *= ", "
            end
        end
        s *= ")"
        return print(io, s)
    else
        return print(io, "")
    end
end

function Base.show(io::IO, o::OnlineStat)
    nms = fields_to_show(o)
    print(io, name(o))
    print(io, "(")
    for nm in nms
        print(io, "$nm = $(getfield(o, nm))")
        nm != nms[end] && print(io, ", ")
    end
    print(io, ")")
end
# function Base.show{I, MatrixOut}(io::IO, o::OnlineStat{I, MatrixOut})
#     nms = fields_to_show(o)
#     print(io, name(o))
#     print(io, "(")
#     for nm in nms
#         print(io, "$nm = $(getfield(o, nm))")
#         nm != nms[end] && print(io, ", ")
#     end
#     print(io, ")")
# end
