# OnlineStats

Online algorithms for statistics.  The driving function in this package is  

```update!(obj, newdata::Vector, addrow::Bool)```

- `newdata`: new Real, Vector, or DataArray  
- `addrow`: append row to results (`true`) or replace current estimates (`false`)


## Types 
Each type defined in OnlineStats contains the fields  

- `<<estimate>>`: Vector of saved estimates
- `n`: number of observations used  
- `nb`: number of batches used

Other fields will be used to store sufficient statistics for online updates.

## Note to developers
Update API docs with

```
julia> using Lexicon
julia> include("src/OnlineStats.jl")
julia> save("docs/OnlineStats.md", OnlineStats)
```

Make webpage changes in master, then use the following
```
mkdocs build  
```
```
git push origin `git subtree split --prefix site master`:gh-pages --force
```
