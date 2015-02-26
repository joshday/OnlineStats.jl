
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

fit = QuantRegSGD(X, y, τ = .6)
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
 :β0       0.253036  
 :β1       1.00141   
 :β2       2.01747   
 :β3       3.02262   
 :β4       3.97585   
 :β5       4.97608   
 :β6       0.050318  
 :β7       0.0513702 
 :β8      -0.0445471 
 :β9      -0.0487734 
 :β10      4.41501e-5
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
0.2713649564847148

````


