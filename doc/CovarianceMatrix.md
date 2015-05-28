
# CovarianceMatrix


````julia
using OnlineStats, StatsBase, Distributions
````





### Create covariance matrix with the first batch
````julia
julia> mycov = 10 * [1 .2 .4; .2 1 .3; .4 .3 1]
3x3 Array{Float64,2}:
 10.0   2.0   4.0
  2.0  10.0   3.0
  4.0   3.0  10.0

````




````julia
mydist =  MvNormal(zeros(3), mycov)
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
  0.00400834 
 -0.000434358
 -0.00236657 

````





#### Covariance Matrix or Correlation Matrix
````julia
julia> cov(o)
3x3 Array{Float64,2}:
 10.0133   1.99375  3.989  
  1.99375  9.97986  2.99624
  3.989    2.99624  9.99608

julia> cor(o)
3x3 Array{Float64,2}:
 1.0       0.199444  0.398714
 0.199444  1.0       0.299985
 0.398714  0.299985  1.0     

````




