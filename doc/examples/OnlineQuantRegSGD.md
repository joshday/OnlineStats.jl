
# OnlineQuantRegSGD


````julia
using OnlineStats
using Distributions
using Gadfly
````





### Generate Data: Location-Shift Model
````julia
beta = [1, 2, 3, 4, 5, 0, 0, 0, 0, 0]
gamma = [1, 1, -1, -1, 2, 2, -2, -2, 0, 0] / 10
````





### Create model with the first batch
````julia
X = randn(100, 10)
errors = (1 + X * gamma) .* randn(100)
y = X * beta + errors

fit = OnlineQuantRegSGD(X, y, τ = .7)
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
 :β0       0.52     
 :β1       1.09101  
 :β2       1.94373  
 :β3       2.91098  
 :β4       4.00638  
 :β5       5.02447  
 :β6       0.153424 
 :β7      -0.114904 
 :β8      -0.124859 
 :β9      -0.0674904
 :β10      0.0507907
 :n        1.0001e6 
 :nb   10001.0      

julia> trueBeta = [quantile(Normal(), .7), beta + gamma * quantile(Normal(), .7)]
11-element Array{Float64,1}:
  0.524401
  1.05244 
  2.05244 
  2.94756 
  3.94756 
  5.10488 
  0.10488 
 -0.10488 
 -0.10488 
  0.0     
  0.0     

julia> maximum(abs(trueBeta - fit.β)) # Max Abs. difference from truth
0.10871496813866255

````


