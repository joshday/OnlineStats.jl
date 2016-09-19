# Online MM algorithm via quadratic upper bound
# Majorizing function: f(u) + ∇f(u)'(Θ - u) + .5 * (Θ - u)'H(Θ - u)
# Q_t(Θ) = (Θ' * A * Θ) + (b' * Θ) + c
# Where:
#   A = (1 - γ) * A + γ * H
#   b = (1 - γ) * b + γ * (∇f(Θ) - H * Θ)


immutable MMQuadUpBound
    A::MatF
    b::VecF
end
function fit!(o::MMQuadUpBound, A, b, γ)
    smooth!(o.A, A, γ)
    smooth!(o.b, b, γ)
end
value(o::MMQuadUpBound) = o.A \ o.b
