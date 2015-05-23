
# CovarianceMatrix


````julia
using OnlineStats, StatsBase, Distributions
````





### Create covariance matrix with the first batch
````julia
mydist =  MvNormal(zeros(3), 10 * [1 .2 .4; .2 1 .3; .4 .3 1])
o = CovarianceMatrix(rand(mydist, 100)')
````





### Update model with many batches
````julia
for i = 1:10000
    updatebatch!(o, rand(mydist, 100)')
end
````





### Check estimate

#### Columns means are available from the `CovarianceMatrix` object.
````julia
julia> mean(o)
3-element Array{Float64,1}:
  0.00189071
 -0.002702  
  0.00286422

````





#### Covariance Matrix or Correlation Matrix
````julia
julia> cov(o)
3x3 Array{Float64,2}:
 9.98952  1.9985   4.00656
 1.9985   9.99055  3.00082
 4.00656  3.00082  9.98436

julia> cor(o)
3x3 Array{Float64,2}:
 1.0       0.200049  0.40118 
 0.200049  1.0       0.300459
 0.40118   0.300459  1.0     

````




