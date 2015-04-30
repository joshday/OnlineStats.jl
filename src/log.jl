
backtrace_list() = [ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Int32), b, 0) for b in backtrace()]
function backtracestring()
	btlist = backtrace_list()
	i = find(x->x[1] == :backtracestring, btlist)[1] + 1
	filename = split(string(btlist[i][2]), "/")[end]
	filenum = btlist[i][3]
	"[$filename:$filenum]"
end

LOG(args...) = println(join(vcat(args..., backtracestring()), " "))

testbtstring() = LOG("Hello","world")
function testbtstring2()
	i = 2
	LOG("i =", 2)
end

