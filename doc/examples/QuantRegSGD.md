
# OnlineQuantRegSGD


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

fit = QuantRegSGD(X, y, τ = .7)
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
 :β0       0.527845  
 :β1       0.99921   
 :β2       2.04046   
 :β3       3.0484    
 :β4       3.95028   
 :β5       4.94829   
 :β6       0.099278  
 :β7       0.106805  
 :β8      -0.0916518 
 :β9      -0.10415   
 :β10     -0.00332631
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
0.013228263318819364

````


