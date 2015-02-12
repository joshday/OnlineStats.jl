using OnlineStats
using Base.Test


#------------------------------------------------------------------------------#
#                                                                       Normal #
#------------------------------------------------------------------------------#
srand(1234)
n1 = 246
n2 = 978
x1 = randn(n1)
x2 = randn(n2)
x = [x1, x2]

obj = OnlineStats.onlinefit(Normal, x1)



