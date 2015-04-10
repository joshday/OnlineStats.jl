
# NormalMix


````julia
using OnlineStats
using Distributions
using Gadfly
````





### True Model/Generate Data
````julia
trueModel = MixtureModel(Normal, [(0, 4), (2, 3), (7, 5), (10, 10)])
x = rand(trueModel, 100_000)
plot(trueModel, -20, 40)
````


![](figures/NormalMix_2_1.png)



### Create model with the first batch
````julia
obj = NormalMix(x[1:100], k=4)
````


````julia
NormalMix:
MixtureModel{Normal}(K = 4)
components[1] (prior = 0.2500):
Normal(μ=-1.175020114360571, σ=24.792101072570414)
components[2]
(prior = 0.2500): Normal(μ=2.7307447444755972, σ=24.792101072570414)
components[3] (prior = 0.2500): Normal(μ=5.371832857847965,
σ=24.792101072570414)
components[4] (prior = 0.2500):
Normal(μ=9.624114103814465, σ=24.792101072570414)
````





### Update model with many batches of size 100
````julia
for i = 2:1000
    newvals = (i - 1) * 100 + 1 : 100 * i
    update!(obj, x[newvals])
end
````





### Check fit
````julia
plot(obj.model, x)
plot(obj.model, -30, 50)
````


![](figures/NormalMix_5_1.png)
![](figures/NormalMix_5_2.png)


