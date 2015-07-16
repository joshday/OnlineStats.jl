# Adaptive Gradient

Example:
```julia
o = Adagrad(x, y)  # ordinary least squares
o = Adagrad(x, y; reg = L2Reg(0.01))  # ridge regression (L2 penalty)
o = Adagrad(x, y; link=LogisticLink(), loss=LogisticLoss()) # logistic regression
```
