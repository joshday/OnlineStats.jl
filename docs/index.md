# OnlineStats

**OnlineStats** is a [Julia](http://julialang.org/) package for statistical models in an online setting.  That is, data arrives in a stream or is too large to fit in RAM.

## Usage
----

### Initialize a model with the specified type.  Types available are:
- `Summary`   
	mean, variance, maximum, minimum
- `QuantileSGD`   
	quantiles via stochastic gradient descent
- `QuantileMM`   
	quantiles via online MM algorithm
	
The fields `obj.n` (number of observations used) and `obj.nb` (number of batches) are included in all types defined in OnlineStats.

### Update your model
- `update!(obj, newdata::Vector)`
	
### View the state of your estimates
- `state(obj)`  

### Convert `obj` to `DataFrame`
- `convert(DataFrame, obj)`

