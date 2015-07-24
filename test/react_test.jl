module ReactTest

using OnlineStats, FactCheck, Reactive
import OnlineStats: row

# include("/home/tom/.julia/v0.4/OnlineStats/src/react.jl")


facts("React") do 
  input = Input(0.0)
  d = Diff()
  m = Mean()
  l = @stream diff(input |> d) |> m

  for x in [5., 8., 3.]
    push!(input, x)
  end

  println(input)
  println(d)
  println(m)
  println(input.children)
  println(l.signals)
  println(l)

  @fact value(input) => 3.
  @fact diff(d) => -5.
  @fact last(d) => 3.
  @fact mean(m) => roughly(-0.666666, atol = 1e-5)


  context("Regression") do
    n, p = 1_000_000, 5;
    x = randn(n, p);
    β = collect(1.:p);
    y = x * β + randn(n)*10;

    input = RegressionInput()
    reg = Adagrad(p)
    l = @stream input |> reg

    for i in 1:length(y)
      push!(input, (row(x,i), y[i]))
    end
    @fact nobs(reg) => n
    @fact coef(reg) => roughly(β, atol = 0.4)
    show(reg); println()

    @time update!(reg, x, y)
    @time for i in 1:length(y)
      push!(input, (row(x,i), y[i]))
    end

  end


end


macro testit(expr::Expr)
  dump(expr, 20)
end

# # some notes on possible syntax:
#   # pipe operator "|>" defines an implicit call to: update_get!(rhs, lhs...) = (update!(rhs, lhs...); rhs)
#   # pipe operator with AVec/tuple as rhs implies you call update_get! for each member of rhs
#   # arrow operator "=>" defines currying: "lhs => f(_)" implies "f(lhs)", "(lhs1, lhs2) => f(_)" implies "(f(lhs1), f(lhs2))"
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

# # the following block:
# @testit begin
#   diff(log(price) |> d) |> window
#   sx = lags(window) |> varx => standardize(_)
#   sy = future(window) |> vary => standardize(_)
#   (sx, sy) |> (reg1, reg2, reg3, reg4, reg5) => (sy - predict(_, sx)) |> swarm
# end

# # should be roughly equivalent to calling this on each new data point:
# function updateprice(price::Float64)
#   update(d, log(price))
#   update!(window, diff(d))
#   sx = standardize(update_get!(varx, lags(window)))
#   sy = standardize(update_get!(vary, future(window)))
#   tmp1 = sy - predict(update_get!(reg1, sx, sy), sx)
#   tmp2 = sy - predict(update_get!(reg2, sx, sy), sx)
#   tmp3 = sy - predict(update_get!(reg3, sx, sy), sx)
#   tmp4 = sy - predict(update_get!(reg4, sx, sy), sx)
#   tmp5 = sy - predict(update_get!(reg5, sx, sy), sx)
#   update!(swarm, (tmp1, tmp2, tmp3, tmp4, tmp5))
# end


end # module