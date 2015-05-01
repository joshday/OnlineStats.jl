
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

LOG(args...) = println(join(vcat(map(string,args)..., backtracestring()), " "))

macro LOG(symbols...)
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

