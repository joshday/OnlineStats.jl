
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
srand(622)
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
 -0.00166873
  0.00431293
 -0.00435478

````





#### Covariance Matrix or Correlation Matrix
````julia
julia> cov(o)
3x3 Array{Float64,2}:
 9.98962  1.99383  3.993  
 1.99383  9.98162  2.99391
 3.993    2.99391  9.99637

julia> cor(o)
3x3 Array{Float64,2}:
 1.0      0.19967   0.39958 
 0.19967  1.0       0.299721
 0.39958  0.299721  1.0     

````




