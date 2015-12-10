
module WindowTest

using OnlineStats, FactCheck

facts("Window") do

  o = Window(Int, [2,4])
  @fact capacity(o) --> 2
  @fact isfull(o) --> false
  @fact length(o) --> 0

  update!(o, 10)
  @fact isfull(o) --> false
  @fact length(o) --> 0

  update!(o, 9:-1:4)
  @fact isfull(o) --> true
  @fact length(o) --> 2
  @fact lags(o) --> [6,8]
  @fact convert(Array, o) --> lags(o)
  @fact o[1] --> 6
  @fact o[2] --> 8
  @fact_throws o[0]
  @fact_throws o[3]
  @fact nobs(o) --> 7

  empty!(o)
  @fact nobs(o) --> 0
  @fact isfull(o) --> false
  @fact length(o) --> 0

  # circ buf
  o = Window(Float64, 3)
  update!(o, 1.5:1:6)
  @fact convert(Array, o) --> [3.5,4.5,5.5]
  @fact nobs(o) --> 5

  # windowed lags
  o = Window(Float64, 0:2)
  update!(o, 1.5:1:6)
  @fact convert(Array, o) --> [5.5,4.5,3.5]
  @fact nobs(o) --> 5
  
end # facts


end # module
