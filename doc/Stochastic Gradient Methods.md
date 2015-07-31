# Available Models using Stochastic Gradient Descent and Variants
The stochastic gradient types take a model argument to specify the link function
and loss function to be used.  Options are:

- `L1Regression`
    - Minimize $\sum |y_i - \mathbf{x}_i^T\mathbf{\beta}|$
- `L2Regression`
- `LogisticRegression`
    - $y \in \{0, 1\}$
- `PoissonRegression`
- `QuantileRegression`
- `SVMLike` (Perceptron and SVM)
    - $y \in \{-1, 1\}$
- `HuberRegression`



### `SGD`

Examples:
```julia
o = SGD(x, y, model = L1Regression())
o = SGD(x, y, model = QuantileRegression(0.5))
```

### `Momentum`

Examples:
```julia
o = Momentum(x, y, model = L2Regression())
o = Momentum(x, y, model = LogisticRegression())
```

### `Adagrad`

Examples:
```julia
o = Adagrad(x, y, model = SVMLike())
o = Adagrad(x, y, model = Huber(2.0))
```
