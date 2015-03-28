
# Compare: `QuantRegSGD` vs. `QuantRegMM`


````julia
using OnlineStats
using Gadfly
using Distributions
using DataFrames
````





### Create model with the first batch

Specify starting value to be 0 for each coefficient.  We will see how well the models recover from poor starting values.

````julia
trueBeta = [0:5]
X = randn(100, 5)
y = vec([ones(100) X] * trueBeta) + randn(100)

obj_sgd = QuantRegSGD(X, y, zeros(6) , τ=.3, r=.6)
obj_mm = QuantRegMM(X, y, zeros(6), τ=.3, r=.6)
````





### Save results for trace plots
````julia
results_sgd = make_df(obj_sgd)
results_mm = make_df(obj_mm)
````





### Update model with many batches
````julia
srand(123)
@time for i = 1:999
	X = randn!(X)
    y = vec([ones(100) X] * trueBeta) + randn(100)

    update!(obj_sgd, X, y)
    make_df!(results_sgd, obj_sgd)
end
````


````julia
elapsed time: 0.149183651 seconds (36556696 bytes allocated, 44.67% gc
time)
````




````julia
srand(123)
@time for i = 1:9999
	X = randn!(X)
    y = vec([ones(100) X] * trueBeta) + randn(100)

    update!(obj_mm, X, y)
    make_df!(results_mm, obj_mm)
end
````


````julia
elapsed time: 1.522353211 seconds (427565608 bytes allocated, 40.24%
gc time)
````





### Check estimates
````julia
julia> coef(obj_sgd)
6-element Array{Float64,1}:
 -0.525847
  1.01551 
  1.99804 
  3.00426 
  3.99402 
  4.98424 

julia> coef(obj_mm)
6-element Array{Float64,1}:
 -0.527165
  0.997568
  2.00217 
  3.00052 
  4.00008 
  4.99934 

julia> 
trueBetaTau = [quantile(Normal(), .3), [1:5]]
6-element Array{Float64,1}:
 -0.524401
  1.0     
  2.0     
  3.0     
  4.0     
  5.0     

julia> 
# SGD: Maximum difference from truth
maxabs(coef(obj_sgd) - trueBetaTau)
0.015762555213357565

julia> 
# MM: Maximum difference from truth
maxabs(coef(obj_mm) - trueBetaTau)
0.0027649352335803457

````





### Check Traceplots

##### Stochastic Gradient Descent:
````julia
results_sgd = melt(results_sgd, 7:8)

plot(results_sgd, x="n", y="value", color="variable", yintercept=trueBetaTau, Geom.line,
Geom.hline(color = color("black")))
````


![](figures/quantregcompare_7_1.png)



##### Online MM Algorithm:
````julia
results_mm = melt(results_mm, 7:8)

plot(results_mm, x="n", y="value", color="variable", yintercept=trueBetaTau, Geom.line,
Geom.hline(color = color("black")))
````


![](figures/quantregcompare_8_1.png)



