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


end # module