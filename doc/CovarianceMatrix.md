
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
 -0.00153492 
 -0.00044411 
  0.000625195

````





#### Covariance Matrix or Correlation Matrix
````julia
julia> cov(o)
3x3 Array{Float64,2}:
 9.99403   2.0017    4.00151
 2.0017   10.0027    3.00238
 4.00151   3.00238  10.035  

julia> cor(o)
3x3 Array{Float64,2}:
 1.0       0.200204  0.399571
 0.200204  1.0       0.299673
 0.399571  0.299673  1.0     

````




