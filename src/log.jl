
backtrace_list() = [ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Int32), b, 0) for b in backtrace()]

const IGNORED_METHODS = Set{Symbol}([:LOG, :publish, :schedule_do])

function backtracestring()

  # get the backtrace and find the position of the "backtracestring()" call
  btlist = backtrace_list()
  btpos = find(x->x[1] == :backtracestring, btlist)[1]
  # println(btlist)

  # find the first non-LOG, non-julia method and return that string
  for i in btpos+1:length(btlist)

    # skip julia internals and LOG calls
    methodsym = btlist[i][1]
    if methodsym in IGNORED_METHODS
      continue
    end

    methodname, pathname, filenum, tmp1, tmp2 = map(string, btlist[i])
    if methodname[1:3] == "jl_"
      continue
    end

    # get the filename from the full path, then return the string
    filename = split(pathname, "/")[end]
    if filename == "FastAnonymous.jl"
      continue
    end

    return "[$filename:$filenum]"
  end
  "[]"
end




# --------------------------------------------------------


immutable LogSeverity
  val::Int
end

const DebugSeverity = LogSeverity(0)
const InfoSeverity = LogSeverity(1)
const ErrorSeverity = LogSeverity(2)


Base.string(sev::LogSeverity) = (sev == DebugSeverity ? "Debug" : (sev == InfoSeverity ? "Info" : "Error"))
Base.print(io::IO, sev::LogSeverity) = print(io, string(sev))
Base.show(io::IO, sev::LogSeverity) = print(io, string(sev))
Base.isless(sev1::LogSeverity, sev2::LogSeverity) = sev1.val < sev2.val

# --------------------------------------------------------

type SevObj
  sev::LogSeverity
  io::IO
end

const LOG_SEVERITY = SevObj(InfoSeverity, STDOUT)

log_severity() = LOG_SEVERITY.sev
log_severity!(sev::LogSeverity) = (LOG_SEVERITY.sev = sev; nothing)

log_io() = LOG_SEVERITY.io
log_io!(io::IO) = (LOG_SEVERITY.io = io; nothing)


# --------------------------------------------------------

LOG(args...) = LOG(InfoSeverity, args...)
DEBUG(args...) = LOG(DebugSeverity, args...)
ERROR(args...) = LOG(ErrorSeverity, args...)

function LOG(sev::LogSeverity, args...)
  if sev >= log_severity()
    io = log_io()
    print(io, "$(NOW()) [$sev]: ")
    for arg in args
      print(io, arg, " ")
    end
    println(io, backtracestring())
      # join(vcat(map(string,args)..., backtracestring()), " "))
  end
end

# note: the macro version give "x: xval" for "@LOG x"


# TODO: maybe change the macros a little:
  # can we get/hardcode the file/linenumber within the macro body?
  # can we wrap the call with an "if log_severity() >= DebugSeverity; DEBUG(...); end" for speed?


# default to InfoSeverity
macro LOG(symbols...)
  expr = :(LOG(InfoSeverity))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end

macro ERROR(symbols...)
  expr = :(LOG(ErrorSeverity))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end

macro DEBUG(symbols...)
  expr = :(LOG(DebugSeverity))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end



