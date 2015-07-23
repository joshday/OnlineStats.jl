module ReactTest

using OnlineStats, FactCheck, Reactive

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
end


end # module