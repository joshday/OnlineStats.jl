
function liftexpr(lhs, rhs, f = :nop)
  gs = gensym()
  fgs = f == :nop ? gs : :($f($gs))
  quote
    lift($gs -> (update!($rhs, $fgs); $rhs), $lhs; init = $rhs)
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

# pass one to many symbols/expressions that either refer to an OnlineStat object, 
# or have it as the first argument to a function call.
# returns a Reactive.Input{inputType} object which you should push! the inputs to
macro stream(expr::Expr)
  expr = applyPipe(expr)
  esc(expr)
end
