module ReactTest

using OnlineStats, FactCheck, Compat
import OnlineStats: row


function oneargtest_base(R)
  d = Diff()
  mn = Mean()
  m = 0.0
  @elapsed for r in R
    update!(d, r)
    update!(mn, abs(diff(d)))
    m = mean(mn)
  end
end

function oneargtest(R)
  d = Diff()
  mn = Mean()
  m = 0.0
  f = @stream mean(abs(diff($1 |> d)) |> mn)
  f(0.0)
  empty!(d); empty!(mn)
  @elapsed for r in R; f(r); end
end


# NOTE: see embedded comments.  lhs = left hand side, rhs = right hand side... referring to the side of the pipe "|>" operator

facts("React") do

  context("DiffMean1") do
    # input = Input(0.0)
    d = Diff()
    m = Mean()

    # the @stream macro returns an anonymous function which updates the full pipeline in one go
    f = @stream diff($1 |> d) |> m
    map(f, [5., 8., 3.])

    println("d: ", d)
    println("m: ", m)
    @fact diff(d) --> -5.
    @fact last(d) --> 3.
    @fact mean(m) --> roughly(-0.666666, atol = 1e-5)
  end

  context("DiffMean2") do
    d = Diff()
    m = Mean()

    # this is a slightly more complicated version, which doesn't update the Mean until the 2nd data point
    f = @stream begin
      df = diff($1 |> d)
      nobs(d) > 1 ? mean(df |> m) : 0.0
    end
    map(f, [5., 8., 3.])

    println("d: ", d)
    println("m: ", m)
    @fact diff(d) --> -5.
    @fact last(d) --> 3.
    @fact mean(m) --> roughly(-1.0, atol = 1e-5)
  end


  context("1 Arg Stream") do

    # warmup
    oneargtest(rand(1))

    # compare speeds of the stream macro vs the equivalent function for 1 argument
    R = rand(10_000_000)
    e = oneargtest(R)
    ebase = oneargtest_base(R)

    @pending e => less_than(ebase * 1.2)
  end

  context("Regression") do
    n, p = 1_000_000, 5;
    x = randn(n, p);
    β = collect(1.:p);
    y = x * β + randn(n)*10;

    reg = SGModel(p, intercept = false, algorithm = Proxgrad())

    # note here... the update! method of SGModel takes an x and y arg, so there
    # should be a 2-item tuple on the left hand side of the pipe
    # $1 refers to the first arg (x) and $2 refers to the second (y)
    f = @stream ($1,$2) |> reg

    for i in 1:length(y)
      f(row(x,i), y[i])
    end
    @fact nobs(reg) --> n
    @fact coef(reg) --> roughly(β, atol = 0.4)
    println(reg)

    @time update!(reg, x, y)
    @time for i in 1:length(y)
      f(row(x,i), y[i])
    end
  end


  context("Mapping pipe and currying") do
    n, p = 1_000_000, 5;
    x = randn(n, p);
    β = collect(1.:p);
    y = x * β + randn(n)*10;

    reg1 = SGModel(p, intercept = false, algorithm = Proxgrad())
    reg2 = SGModel(p, intercept = false, algorithm = SGD())
    reg3 = LinReg(p)

    # there are a few things to note here:
    #   1) when there is a tuple on the rhs of the pipe, it will return a block... one expression per rhs item
    #      note: I've taken to calling this a "mapping pipe"
    #   2) the pipe operator can be used for both streaming (calling update!) and for currying (injecting lhs into underscore on rhs)
    #   3) if there's a currying expression after a mapping pipe, it will inject the expression into each
    #      item in the return tuple of the lhs.

    # This example is equivalent to:
    # f(x,y) -> begin
    #   tmp1 = update_get!(reg1, x, y)
    #   tmp2 = update_get!(reg2, x, y)
    #   (y - predict(tmp1, x)), y - predict(tmp2, x)))
    # end
    f = @stream ($1,$2) |> (reg1, reg2) |> $2 - predict(_, $1)
    # # dump(f.code)

    for i in 1:length(y)
      outval = f(row(x,i), y[i])

      if i == length(y)
        @fact typeof(outval) --> @compat Tuple{Float64, Float64}
        @fact abs(outval[2] - outval[1]) --> roughly(0.0, atol = 1.0)
        # @fact abs(outval[3] - outval[1]) --> roughly(0.0, atol = 0.1)
        println("outval: ", outval)

        println(@code_typed f(row(x,i),y[i]))
      end
    end

    @fact nobs(reg1) --> n
    @fact coef(reg1) --> roughly(β, atol = 1.0)
    println(reg1)

    @fact nobs(reg2) --> n
    @fact coef(reg2) --> roughly(β, atol = 1.0)
    println(reg2)

    # @fact nobs(reg3) --> n
    # @fact coef(reg3) --> roughly(β, atol = 0.4)
    # println(reg3)

    @time begin
      update!(reg1, x, y)
      update!(reg2, x, y)
    end
    @time for i in 1:length(y)
      f(row(x,i), y[i])
    end

  end

end


# -----------------------------------------------------------------

# NOTE: everything below is unused... keeping the notes around for now.  TODO: delete

# # some notes on possible syntax:
#   # pipe operator "|>" defines an implicit call to: update_get!(rhs, lhs...) = (update!(rhs, lhs...); rhs)
#   # pipe operator with AVec/tuple as rhs implies you call update_get! for each member of rhs
#   # arrow operator "-->" defines currying: "lhs --> f(_)" implies "f(lhs)", "(lhs1, lhs2) --> f(_)" implies "(f(lhs1), f(lhs2))"
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

# @testit begin
#   diff(log($1) |> d) |> window
#   sx = lags(window) |> varx |> standardize(_)
#   sy = future(window) |> vary |> standardize(_)
#   (sx, sy) |> (reg1, reg2, reg3, reg4, reg5) |> (sy - predict(_, sx)) |> swarm
# end


# # the following block:
# str = @stream begin
#   diff(log($1) |> d) |> window
#   sx = lags(window) |> varx |> standardize(_)
#   sy = future(window) |> vary |> standardize(_)
#   (sx, sy) |> (reg1, reg2, reg3, reg4, reg5) |> (sy - predict(_, sx)) |> swarm
# end

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
