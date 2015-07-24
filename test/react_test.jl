module ReactTest

using OnlineStats, FactCheck, Reactive
import OnlineStats: row

# include("/home/tom/.julia/v0.4/OnlineStats/src/react.jl")


# facts("React") do 
#   input = Input(0.0)
#   d = Diff()
#   m = Mean()
#   l = @stream diff(input |> d) |> m

#   for x in [5., 8., 3.]
#     push!(input, x)
#   end

#   println(input)
#   println(d)
#   println(m)
#   println(input.children)
#   println(l.signals)
#   println(l)

#   @fact value(input) => 3.
#   @fact diff(d) => -5.
#   @fact last(d) => 3.
#   @fact mean(m) => roughly(-0.666666, atol = 1e-5)


#   context("Regression") do
#     n, p = 1_000_000, 5;
#     x = randn(n, p);
#     β = collect(1.:p);
#     y = x * β + randn(n)*10;

#     input = RegressionInput()
#     reg = Adagrad(p)
#     l = @stream input |> reg

#     for i in 1:length(y)
#       push!(input, (row(x,i), y[i]))
#     end
#     @fact nobs(reg) => n
#     @fact coef(reg) => roughly(β, atol = 0.4)
#     show(reg); println()

#     @time update!(reg, x, y)
#     @time for i in 1:length(y)
#       push!(input, (row(x,i), y[i]))
#     end

#   end


# end


macro testit(expr::Expr)
  dump(expr, 20)
end

# -----------------------------------------------------------------


# function liftexpr(lhs, rhs, f = :nop)
#   gs = gensym()
#   fgs = f == :nop ? gs : :($f($gs))
#   quote
#     lift($gs -> (update!($rhs, $fgs...); $rhs), $lhs; init = $rhs)
#   end
# end

# applyPipe(sym::Symbol) = sym

# function applyPipe(expr::Expr)
#   @assert expr.head == :call
#   fname = expr.args[1]
#   @assert fname == :|>
      
#   lhs, rhs = expr.args[2:3]
#   @assert isa(rhs, Symbol)
#   # TODO: we assume rhs is an OnlineStat... can we assert this and error now?

#   if isa(lhs, Symbol)
#     # both sides are symbols... return the lift expression
#     return liftexpr(lhs, rhs)
#   end

#   # if we're here, then we have a Symbol on the RHS (presumably an OnlineStat) but something else on the LHS
#   # NOTE: to keep it simple, assume there is a single function with a single input, which is a Signal
#   @assert isa(lhs, Expr)
#   @assert lhs.head == :call
#   @assert length(lhs.args) == 2  # should be a function call with 1 param... function symbols is args[1], param is args[2]
#   f = lhs.args[1]
#   lhs = applyPipe(lhs.args[2])
#   return liftexpr(lhs, rhs, f)
# end

update_get!(o::OnlineStat, args...) = (update!(o, args...); o)
update_get!(o::OnlineStat, t::Tuple) = update_get!(o, t...)

function handlePipeExpr(lhs, rhs)

  println("!!PIPE!! ", lhs, " ::: ", rhs)
  if isa(rhs, Expr) && rhs.head == :tuple

    # special handling... apply this pipe to each element in the tuple, and return a tuple of the gensyms
    blk = Expr(:block)
    gensyms = Symbol[]
    for rhsitem in rhs.args
      # create a pipe expression "gensym() = lhs |> rhsitem" and add it to the block
      gs = gensym()
      push!(gensyms, gs)
      pipeexpr = handlePipeExpr(lhs, rhsitem)
      push!(blk.args, :($gs = $pipeexpr))
    end

    # now the final item in the block returns the tuple of gensyms
    gsexpr = Expr(:tuple)
    gsexpr.args = gensyms
    push!(blk.args, gsexpr)

    # finally done... return the block
    return blk
  end

  # if we got here, it's a normal pipe operation
  gs = gensym()
  quote
    $gs = $(buildStreamExpr(lhs))
    update_get!($rhs, $gs)
  end
end


replaceUnderscore(sym::Symbol, gs::Symbol) = (sym == :_ ? gs : sym)
function replaceUnderscore(expr::Expr, gs::Symbol)
  println("!!UNDER!! ", expr, " ::: ", gs)
  expr.args = map(ex->replaceUnderscore(ex,gs), expr.args)
  buildStreamExpr(expr)
end

# create a new expression which replaces any symbol "_" in the rhs with a gensym of the lhs
function handleCurryingExpr(lhs, rhs)
  gs = gensym()
  quote
    $gs = $(buildStreamExpr(lhs))
    $(replaceUnderscore(rhs, gs))
  end
end


buildStreamExpr(sym::Symbol) = sym

function buildStreamExpr(expr::Expr, )
  head = expr.head
  if head == :block || head == :tuple

    # map build to each arg in the block
    expr.args = map(buildStreamExpr, expr.args)
    return expr
  
  elseif head == :line
    
    # keep this as-is
    return expr

  elseif head == :$

    # if it's an integer i, replace with INPUT[i]
    isa(expr.args[1], Int) || error("Cannot use dollar sign in stream macro unless referring to input (i.e. \$2 refers to the 2nd input): $expr")
    return :(INPUT[$(expr.args[1])])

  elseif head == :(=)

    # local variable... make sure we have a symbol on the lhs, then
    # recursively call this on the rhs
    println("!!! = !!! ", expr)
    @assert isa(expr.args[1], Symbol)
    expr.args[2] = buildStreamExpr(expr.args[2])
    return expr

  elseif head == :call

    # operators and functions
    fname = expr.args[1]
    @assert isa(fname, Symbol)
    if fname == :|>

      # pipe symbol could be streaming or currying
      lhs, rhs = expr.args[2:3]
      if isa(rhs, Symbol) || (isa(rhs, Expr) && rhs.head == :tuple)
        return handlePipeExpr(lhs, rhs)
      elseif isa(rhs, Expr)
        return handleCurryingExpr(lhs, rhs)
      else
        error("Unexpected rhs in buildStreamExpr pipe: $expr")
      end

    else

      # normal expression... recursively call this on the arguments
      expr.args[2:end] = map(buildStreamExpr, expr.args[2:end])
      return expr

    end
  else
    error("Unexpected expr in buildStreamExpr: $expr")
  end
end

# pass one to many symbols/expressions that either refer to an OnlineStat object, 
# or have it as the first argument to a function call.
# returns a Reactive.Input{inputType} object which you should push! the inputs to
macro stream(expr::Expr)
  fbody = buildStreamExpr(expr)
  # println(expr)
  println(expr)

  esc(quote
    (INPUT...) -> $fbody
  end)
end


# # some notes on possible syntax:
#   # pipe operator "|>" defines an implicit call to: update_get!(rhs, lhs...) = (update!(rhs, lhs...); rhs)
#   # pipe operator with AVec/tuple as rhs implies you call update_get! for each member of rhs
#   # arrow operator "=>" defines currying: "lhs => f(_)" implies "f(lhs)", "(lhs1, lhs2) => f(_)" implies "(f(lhs1), f(lhs2))"
        # NOTE: maybe we can always use the pipe operator "|>"?? 
        #       If rhs is a Symbol, assume it's the update_get!() version, otherwise assume currying
#   # equal "=" tags that node with a symbol (instead of using a gensym)

# # update_get!(o, args...) is the temporary name for doing: (update!(o, args...); o)

# # assuming these rough definitions, trying to model an AR(p) of log 
# # returns with some aggregate of 5 different regression models:
# price = FloatInput()
# d = Diff()
# w = Window(p)
# varx = Variances(p)
# vary = Variance()
# reg1 = Adagrad(p)
# reg2 = LinReg(p)
# ...
# reg5 = ???
# swarm = Swarm([reg1, ... , reg5])

@testit begin
  diff(log($1) |> d) |> window
  sx = lags(window) |> varx |> standardize(_)
  sy = future(window) |> vary |> standardize(_)
  (sx, sy) |> (reg1, reg2, reg3, reg4, reg5) |> (sy - predict(_, sx)) |> swarm
end


# the following block:
str = @stream begin
  diff(log($1) |> d) |> window
  sx = lags(window) |> varx |> standardize(_)
  sy = future(window) |> vary |> standardize(_)
  (sx, sy) |> (reg1, reg2, reg3, reg4, reg5) |> (sy - predict(_, sx)) |> swarm
end

# # should be roughly equivalent to returning an anonymous function:
# (INPUT...) -> begin
#   update_get!(window, diff(update_get!(d, log(INPUT[1]))))
#   sx = standardize(update_get!(varx, lags(window)))
#   sy = standardize(update_get!(vary, future(window)))
#   tmp1 = sy - predict(update_get!(reg1, sx, sy), sx)
#   tmp2 = sy - predict(update_get!(reg2, sx, sy), sx)
#   tmp3 = sy - predict(update_get!(reg3, sx, sy), sx)
#   tmp4 = sy - predict(update_get!(reg4, sx, sy), sx)
#   tmp5 = sy - predict(update_get!(reg5, sx, sy), sx)
#   update!(swarm, tmp1, tmp2, tmp3, tmp4, tmp5)
# end


end # module