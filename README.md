# OnlineStats

Online algorithms for statistics.  The driving function in this package is  

```update!(obj, newdata::Vector, addrow::Bool)```

where obj has one of the following types:  
- `Summary`  
- `Quantile` 

`newdata` is the vector of new observations.  

`addrow` is whether the new update should replace the previous update (`false`) or a new row should be added (`true`)