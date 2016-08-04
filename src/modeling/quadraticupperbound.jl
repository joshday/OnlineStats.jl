# Online MM algorithm via quadratic upper bound
# Majorizing function: f(u) + ∇f(u)'(Θ - u) + .5 * (Θ - u)'H(Θ - u)
# Q_t(Θ) = g'Θ + Θ'HΘ/2 + Θ'Hu + c
# Θ_t = inv(H) * (Hu - g)
immutable MMQuadUpBound
    g::VecF
    H::MatF
    Hu::VecF
end
function fit!(o::MMQuadUpBound, g, H, Hu, γ)
    smooth!(o.g, g, γ)
    smooth!(o.H, H, γ)
    smooth!(o.Hu, Hu, γ)
end
value(o::MMQuadUpBound) = o.H \ (o.Hu - o.g)
