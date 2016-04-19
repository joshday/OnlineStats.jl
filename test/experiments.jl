module Experiments
reload("OnlineStats"); reload("SparseRegression")
using OnlineStats, StatsBase, GLMNet, Convex, Mosek
import SparseRegression
sp = SparseRegression
predict = StatsBase.predict

n, p = 10_000, 5
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

λ = .1

o = LinReg(x, y, LassoPenalty(λ))
o2 = sp.SparseReg(x, y, penalty = sp.LassoPenalty(), lambda = [λ], step = 1., tol = 1e-7, intercept = false)
g = glmnet(x, y, lambda = [λ], intercept = false, tol = 1e-7)
β = Variable(p)
problem = minimize(.5 * sumsquares(y - x*β) / n + λ * sumabs(β))
solve!(problem, MosekSolver(LOG=0))

display([g.betas[j] for j in 1:length(g.betas)])                           # GLMNet
# display(coef(o, tol = 1e-10)[2:end])    # OnlineStats
display(β.value)                        # Convex
display(coef(o2))                # SparseReg

# yhat_OnlineStats = predict(o, x)
# yhat_SparseRegression = predict(o2, x)
# yhat_GLMNet = GLMNet.predict(g, x)

end
