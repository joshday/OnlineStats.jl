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
    print(io, "  >" * @sprintf("%18s", name * " : "), value)
    newline && println(io)
end
function print_item(io::IO, o::OnlineStat, newline=true)
    print_item(io, name(o), pretty(value(o)), newline)
end


fields_to_show(o::OnlineStat) = fieldnames(o)

function Base.show(io::IO, o::OnlineStat)
    print(io, name(o))
    show_fields(io, o)
end
function show_fields(io::IO, o::OnlineStat)
    nms = fields_to_show(o)
    print(io, "(")
    for nm in nms
        print(io, "$nm = $(pretty(getfield(o, nm)))")
        nm != nms[end] && print(io, ", ")
    end
    print(io, ")")
end

pretty(arg) = arg
pretty(arg::AbstractFloat) = @sprintf("%F", arg)
