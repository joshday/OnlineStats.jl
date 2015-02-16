# Summary



### `Summary`


### `CovarianceMatrix`
```julia
using RDatasets
iris = dataset("datasets", iris)

# DataFrame support not currently implemented

# Suppose our data is in 3 batches
iris1 = array(iris[1:50, 1:4])
iris2 = array(iris[51:100, 1:4])
iris3 = array(iris[101:150, 1:4])

# Create our object
obj = OnlineStats.CovarianceMatrix(iris1)

# Take a look at the covariance for the first batch:
OnlineStats.state(obj)
```