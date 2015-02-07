using OnlineStats
using Base.Test

# ALL TESTING NEEDS TO BE REDONE

#------------------------------------------------------------------------------#
#                                                 Simulate two batches of data #
#------------------------------------------------------------------------------#
srand(1234)
n1 = 246
n2 = 978
x1 = rand(n1)
x2 = rand(n2)


#------------------------------------------------------------------------------#
#                                                      Mean: oMean and update! #
#------------------------------------------------------------------------------#
obj = oMean(x1)
@test obj.statistic == "mean"
@test obj.estimate == mean(x1)
@test obj.n == n1
@test obj.nBatch == 1

update!(obj, x2)
@test obj.statistic == "mean"
@test obj.estimate == mean([x1,x2])
@test obj.n == n1 + n2
@test obj.nBatch == 2

#------------------------------------------------------------------------------#
#                                                   Variance: oVar and update! #
#------------------------------------------------------------------------------#
obj = oVar(x1)
@test obj.statistic == "var, mean"
@test obj.estimate == (var(x1), mean(x1))
@test obj.n == n1
@test obj.nBatch == 1

update!(obj, x2)
@test obj.statistic == "var, mean"
@test obj.estimate[1] == var([x1, x2])
@test obj.estimate[2] == mean([x1, x2])
@test obj.n == n1 + n2
@test obj.nBatch == 2


#------------------------------------------------------------------------------#
#                                                         Quantile and update! #
#------------------------------------------------------------------------------#
obj = oQuantile(x1, .5)

