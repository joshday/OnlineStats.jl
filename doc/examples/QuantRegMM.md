
# OnlineQuantRegMM


````julia
using OnlineStats
using Distributions
using Gadfly
````





### Generate Data: Location-Shift Model
````julia
beta = [1, 2, 3, 4, 5, 0, 0, 0, 0, 0]
gamma = [0, 1, 1, -1, -1, 2, 2, -2, -2, 0] / 10
````





### Create model with the first batch
````julia
X = randn(100, 10)
errors = (1 + X * gamma) .* randn(100)
y = X * beta + errors

fit = QuantRegMM(X, y, τ = .7)
````





### Update model with many batches
````julia
for i = 1:10000
	
	X = randn(100, 10)
	errors = (1 + X * gamma) .* randn(100)
	y = X * beta + errors

	update!(fit, X, y)
end
````





### Check fit
````julia
julia> state(fit)
13x2 Array{Any,2}:
 :β0       0.52441   
 :β1       1.00159   
 :β2       2.05402   
 :β3       3.05029   
 :β4       3.94942   
 :β5       4.95155   
 :β6       0.0979459 
 :β7       0.0990952 
 :β8      -0.0964911 
 :β9      -0.10422   
 :β10     -0.00164849
 :n        1.0001e6  
 :nb   10001.0       

julia> trueBeta = [quantile(Normal(), .7); beta + gamma * quantile(Normal(), .7)]
11-element Array{Float64,1}:
  0.524401
  1.0     
  2.05244 
  3.05244 
  3.94756 
  4.94756 
  0.10488 
  0.10488 
 -0.10488 
 -0.10488 
  0.0     

julia> maximum(abs(trueBeta - fit.β))
0.008389000840355626

````


