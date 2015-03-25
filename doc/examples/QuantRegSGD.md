
# OnlineQuantRegSGD


````julia
using OnlineStats
using Distributions, StatsBase, Gadfly
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

julia> maxabs(trueBeta - coef(fit))
0.006399658767272776

````


