
using OnlineStats, Reactive
nop(x) = x

module OS_React

export @stream

# """
# Float64 -> update!(o, x)
# """
# function Reactive.lift(o::OnlineStat, input::Signal, finput::Function = nop, foutput::Function = nop)

# end


function liftexpr(lhs, rhs, f = :nop)
  gs = gensym()
  # :(lift($gs -> (update!($(esc(rhs)), $(esc(f))($gs)); $(esc(rhs))), $(esc(lhs)); init = $(esc(rhs))))
  quote
    lift($gs -> (update!($rhs, $f($gs)); $rhs), $lhs; init = $rhs)
  end
end

applyPipe(sym::Symbol) = sym

function applyPipe(expr::Expr)
  @assert expr.head == :call
  fname = expr.args[1]
  @assert fname == :|>
      
  lhs, rhs = expr.args[2:3]
  @assert isa(rhs, Symbol)
  # TODO: we assume rhs is an OnlineStat... can we assert this and error now?

  if isa(lhs, Symbol)
    # both sides are symbols... return the lift expression
    return liftexpr(lhs, rhs)
  end

  # if we're here, then we have a Symbol on the RHS (presumably an OnlineStat) but something else on the LHS
  # NOTE: to keep it simple, assume there is a single function with a single input, which is a Signal
  @assert isa(lhs, Expr)
  @assert lhs.head == :call
  @assert length(lhs.args) == 2  # should be a function call with 1 param... function symbols is args[1], param is args[2]
  f = lhs.args[1]
  lhs = applyPipe(lhs.args[2])
  return liftexpr(lhs, rhs, f)
end

macro test(expr)
  x = :hi
  esc(quote
    $(esc(x))
  end)
end

# pass one to many symbols/expressions that either refer to an OnlineStat object, 
# or have it as the first argument to a function call.
# returns a Reactive.Input{inputType} object which you should push! the inputs to
macro stream(expr::Expr)

  # dump(expr, 15)
  # println("--------------")
  expr = applyPipe(expr)
  # println("--------------")
  # dump(expr, 20)

  esc(expr)
end

end # module
osr = OS_React;
