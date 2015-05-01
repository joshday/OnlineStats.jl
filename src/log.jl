
backtrace_list() = [ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Int32), b, 0) for b in backtrace()]

function backtracestring()

	btlist = backtrace_list()
	tmp = find(x->x[1] == :LOG, btlist)
	if isempty(tmp)
		tmp = find(x->x[1] == :backtracestring, btlist)
	end
	
	i = tmp[1] + 1
	filename = split(string(btlist[i][2]), "/")[end]
	filenum = btlist[i][3]
	"[$filename:$filenum]"
end




# --------------------------------------------------------

@enum LogSeverity DEBUG INFO ERROR

type SevObj
	sev::LogSeverity
end

const LOG_SEVERITY = SevObj(INFO)

log_severity() = LOG_SEVERITY.sev
log_severity(sev::LogSeverity) = (LOG_SEVERITY.sev = sev)

Base.isless(sev1::LogSeverity, sev2::LogSeverity) = sev1.val < sev2.val

# --------------------------------------------------------

LOG(args...) = LOG(INFO, args...)

function LOG(sev::LogSeverity, args...)
	if sev >= log_severity()
		println(string(log_severity()), ": ", join(vcat(map(string,args)..., backtracestring()), " "))
	end
end


# default to INFO
macro LOG(symbols...)
	# s1 = eval(symbols[1])
	# local sev
	# if isa(s1, LogSeverity)
	# 	sev = s1
	# 	symbols = symbols[2:end]
	# else 
	# end

	sev = INFO
	if sev < log_severity()
		return
	end

  expr = :(LOG())
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end


#------------------------------------------------------- Simple tests/examples 

testbtstring() = LOG("Hello","world")
function testbtstring2()
	i,j = 2, 23432.23423
	@LOG(i, j)
end

