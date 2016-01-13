# # Josh: I changed update_get! -> fit_get! and update! -> fit!.  Does everything
# # still work?  I can't follow everything here.
#
# fit_get!(o::OnlineStat, args...) = (fit!(o, args...); o)
# fit_get!(o::OnlineStat, t::Tuple) = fit_get!(o, t...)
#
# function handlePipeExpr(lhs, rhs)
#
#   # println("!!PIPE!! ", lhs, " ::: ", rhs)
#   if isa(rhs, Expr) && rhs.head == :tuple
#
#     # special handling... apply this pipe to each element in the tuple, and return a tuple of the gensyms
#     blk = Expr(:block)
#     gensyms = Symbol[]
#     for rhsitem in rhs.args
#       # create a pipe expression "gensym() = lhs |> rhsitem" and add it to the block
#       gs = gensym()
#       push!(gensyms, gs)
#       pipeexpr = handlePipeExpr(lhs, rhsitem)
#       push!(blk.args, :($gs = $pipeexpr))
#     end
#
#     # now the final item in the block returns the tuple of gensyms
#     gsexpr = Expr(:tuple)
#     gsexpr.args = gensyms
#     push!(blk.args, gsexpr)
#
#     # finally done... return the block
#     return blk
#   end
#
#   # if we got here, it's a normal pipe operation
#   gs = gensym()
#   lhs = buildStreamExpr(lhs)[1]
#
#   # if lhs is a tuple, splat the arguments directly into the call to fit_get!
#   if isa(lhs, Expr) && lhs.head == :tuple
#     return :(fit_get!($rhs, $(lhs.args...)))
#   end
#
#   # must be a single argument
#   return :(fit_get!($rhs, $lhs))
#
#   # quote
#   #   $gs = $lhs
#   #   fit_get!($rhs, $gs)
#   # end
# end
#
# getMaxArg(s) = 0
# function getMaxArg(expr::Expr)
#   if expr.head == :$
#     inputnum = expr.args[1]
#     isa(inputnum, Int) || error("Cannot use dollar sign in stream macro unless referring to input (i.e. \$2 refers to the 2nd input): $expr")
#     return inputnum
#   else
#     return maximum(map(getMaxArg, expr.args))
#   end
# end
#
#
# replaceUnderscore(sym, gs::Symbol) = (sym == :_ ? gs : sym)
# function replaceUnderscore(expr::Expr, gs::Symbol)
#   # println("!!UNDER!! ", expr, " ::: ", gs)
#   expr.args = map(ex->replaceUnderscore(ex,gs), expr.args)
#   buildStreamExpr(expr)[1]
# end
#
# # create a new expression which replaces any symbol "_" in the rhs with a gensym of the lhs
# function handleCurryingExpr(lhs, rhs)
#
#   # first we process the lhs, and figure out whether there is a "mapping pipeline"
#   lhs, ismapped = buildStreamExpr(lhs)
#
#   if ismapped
#
#     # special handling if the lhs is a "mapping pipeline"
#     # for every gensym in the return tuple, inject the rhs but replacing the underscore with that element's gensym
#     # dump(lhs)
#     lhs_return_tuple = lhs.args[end]
#     for (i,lhsgs) in enumerate(lhs_return_tuple.args)
#       lhs_return_tuple.args[i] = replaceUnderscore(copy(rhs), lhsgs)
#     end
#
#     # we've now injected this expression into the return tuple of the lhs...
#     # return that, plus tell the next curry to continue mapping
#     return lhs, ismapped
#
#   else
#
#     # not mapped, so return a new expr
#     gs = gensym()
#     rhs =  replaceUnderscore(rhs, gs)
#     blk = quote
#       $gs = $lhs
#       $rhs
#     end
#     return blk, false
#   end
# end
#
# type StreamParamInfo
#   numInputs::Int
# end
# const STREAMPARAMS = StreamParamInfo(1)
#
#
# buildStreamExpr(x) = x, false
#
# function buildStreamExpr(expr::Expr)
#   head = expr.head
#   if head == :block || head == :tuple
#
#     # map build to each arg in the block
#     expr.args = map(ex -> buildStreamExpr(ex)[1], expr.args)
#     return expr, false
#
#   elseif head == :line
#
#     # keep this as-is
#     return expr, false
#
#   elseif head == :$
#
#     # if it's an integer i, replace with INPUT[i], (or INPUT for the 1-arg case)
#     inputnum = expr.args[1]
#     isa(inputnum, Int) || error("Cannot use dollar sign in stream macro unless referring to input (i.e. \$2 refers to the 2nd input): $expr")
#     @assert inputnum <= STREAMPARAMS.numInputs
#     return symbol(string("INPUT", inputnum)), false
#     # if STREAMPARAMS.numInputs > 1
#     #   return :(INPUT[$inputnum]), false
#     # else
#     #   return :INPUT, false
#     # end
#
#   elseif head == :(=)
#
#     # local variable... make sure we have a symbol on the lhs, then
#     # recursively call this on the rhs
#     # println("!!! = !!! ", expr)
#     @assert isa(expr.args[1], Symbol)
#     expr.args[2] = buildStreamExpr(expr.args[2])[1]
#     return expr, false
#
#   elseif head == :call
#
#     # operators and functions
#     fname = expr.args[1]
#     @assert isa(fname, Symbol)
#     if fname == :|>
#
#       # pipe symbol could be streaming or currying
#       lhs, rhs = expr.args[2:3]
#       if isa(rhs, Symbol)
#         return handlePipeExpr(lhs, rhs), false
#       elseif isa(rhs, Expr) && rhs.head == :tuple
#         return handlePipeExpr(lhs, rhs), true
#       elseif isa(rhs, Expr)
#         return handleCurryingExpr(lhs, rhs)
#       else
#         error("Unexpected rhs in buildStreamExpr pipe: $expr")
#       end
#
#     else
#
#       # normal expression... recursively call this on the arguments
#       # expr.args[2:end] = map(buildStreamExpr, expr.args[2:end])
#       expr.args = map(ex -> buildStreamExpr(ex)[1], expr.args)
#       return expr, false
#
#     end
#   else
#     # dump(expr,20)
#     # warn("Unexpected expr in buildStreamExpr: $expr")
#
#     # map build to each arg in the block
#     expr.args = map(ex -> buildStreamExpr(ex)[1], expr.args)
#     return expr, false
#   end
# end
#
# """
# Define pipelines of streaming data that include updating OnlineStats.
# The @stream macro creates an anonymous function to calculate a full
# data pipeline on a new data point.  Wrap in begin/end blocks for complex
# processing.  Use "\$i" to refer to the ith argument, and "_" (underscore)
# to curry results through a pipeline.
# Some features:
#   - update univariate and multivariate OnlineStats, with chaining:
#         myMean = Mean()
#         f = @stream mean(\$1 |> myMean)
#         runningMean = map(f, 0.:10)
#         # should create the series: runningMean == 0.0 : 0.5 : 5.0
#         myRegression = Adagrad(10)
#         f = @stream (\$1,\$2) |> myRegression
#         # now call f(x,y) to update the regression
#   - apply arbitrary functions and control flow:
#         myMean1 = Mean()
#         myMean2 = Mean()
#         f = @stream begin
#           if \$1 > 0.0
#             return log(mean(\$2 |> myMean1)) - 1.0
#           end
#           mean(\$2 |> myMean2)
#         end
#   - mapping pipelines allow you to update many OnlineStats with the same expression,
#     plus continue the mapping into curried results:
#       This example:
#         reg1 = Adagrad(p)
#         reg2 = SGD(p)
#         f = @stream (\$1,\$2) |> (reg1, reg2) |> \$2 - predict(_, \$1)
#       is equivalent to creating:
#         function f(x,y)
#           tmp1 = fit_get!(reg1, x, y)
#           tmp2 = fit_get!(reg2, x, y)
#           (y - predict(tmp1, x)), y - predict(tmp2, x)))
#         end
# """
# macro stream(expr::Expr)
#
#   # figure out the biggest $i arg
#   STREAMPARAMS.numInputs = getMaxArg(expr)
#   # println("GOT: ", STREAMPARAMS.numInputs)
#   if STREAMPARAMS.numInputs > 10
#     error("too many inputs in stream: maxInputs=$(STREAMPARAMS.numInputs)  expr: $expr")
#   end
#
#   # generate a unique function name, and spell out the args: ##streamed##1232(INPUT1, INPUT2)
#   fname = gensym("streamed")
#   # println(fname)
#   fargs = [symbol(string("INPUT",i)) for i in 1:STREAMPARAMS.numInputs]
#   # println(fargs)
#
#   # now create the function body
#   # print("Before: "); dump(expr, 20)
#   fbody,_ = buildStreamExpr(expr)
#   # print("After : "); dump(fbody, 20)
#   # println(fbody)
#
#
#   blk = esc(quote
#     function $fname($(fargs...))
#       $fbody
#     end
#     $fname
#   end)
#   println(blk)
#   blk
# end
#
#
# # -------------------------------------------------------------------------------
# # NOTE: everything below is an old implementation leveraging Reactive.jl... it was too slow, so I abandoned it
#
# # # some helper methods to create Input types
# # RealInput{T<:Real}(::Type{T}) = Input(zero(T))
# # FloatInput() = RealInput(Float64)
# # IntInput() = RealInput(Int)
# # VecInput{T<:Real}(::Type{T}) = Input{AVec{T}}(zeros(T,0))
# # VecInput() = VecInput(Float64)
# # RegressionInput{T<:Real}(::Type{T}) = Input{ Tuple{AVec{T},T}}((zeros(T,0),zero(T)))
# # RegressionInput() = RegressionInput(Float64)
#
#
# # function liftexpr(lhs, rhs, f = :nop)
# #   gs = gensym()
# #   fgs = f == :nop ? gs : :($f($gs))
# #   quote
# #     lift($gs -> (fit!($rhs, $fgs...); $rhs), $lhs; init = $rhs)
# #   end
# # end
#
# # applyPipe(sym::Symbol) = sym
#
# # function applyPipe(expr::Expr)
# #   @assert expr.head == :call
# #   fname = expr.args[1]
# #   @assert fname == :|>
#
# #   lhs, rhs = expr.args[2:3]
# #   @assert isa(rhs, Symbol)
# #   # TODO: we assume rhs is an OnlineStat... can we assert this and error now?
#
# #   if isa(lhs, Symbol)
# #     # both sides are symbols... return the lift expression
# #     return liftexpr(lhs, rhs)
# #   end
#
# #   # if we're here, then we have a Symbol on the RHS (presumably an OnlineStat) but something else on the LHS
# #   # NOTE: to keep it simple, assume there is a single function with a single input, which is a Signal
# #   @assert isa(lhs, Expr)
# #   @assert lhs.head == :call
# #   @assert length(lhs.args) == 2  # should be a function call with 1 param... function symbols is args[1], param is args[2]
# #   f = lhs.args[1]
# #   lhs = applyPipe(lhs.args[2])
# #   return liftexpr(lhs, rhs, f)
# # end
#
# # # pass one to many symbols/expressions that either refer to an OnlineStat object,
# # # or have it as the first argument to a function call.
# # # returns a Reactive.Input{inputType} object which you should push! the inputs to
# # macro stream(expr::Expr)
# #   expr = applyPipe(expr)
# #   # println(expr)
# #   esc(expr)
# # end
