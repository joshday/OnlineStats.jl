
# implements the online flexible least squares algorithm... modeled on Montana et al (2009):
#   "Flexible least squares for temporal data mining and statistical arbitrage"

# Our cost function: Cₜ(βₜ; μ) = (yₜ - xₜ'βₜ)² + μ ‖Δβₜ‖²
#   Below we use Vω = μ⁻¹Iₚ  along with a nicer to use relationship: μ = (1 - δ) / δ
#   We accept 0 <= δ <= 1 as a constructor argument which controls the weighting of new observations
#   δ close to 0 corresponds to large μ, which means the parameter vector β changes slowly
#   δ close to 1 corresponds to small μ, which means the parameter vector β changes quickly

# OnlineFLS: Thomas Breloff (Cointegrated Technologies)



# TODO: allow for time-varying Vω???
#  to accomplish... lets represent Vω as a vector of Variance's (i.e. the diagonal of Vω)

#-------------------------------------------------------# Type and Constructors

type OnlineFLS <: OnlineStat
	p::Int  		# number of independent vars
	Vω::MatF    # pxp (const) covariance matrix of Δβₜ
	# Vω::Vector{Variance}
	Vε::Variance     # variance of error term
	yvar::Variance   # used for normalization
	xvars::Variances  # used for normalization
	# weighting::W  # weighting scheme for Variances... algo convergence is dictated by Vω

	n::Int
	β::VecF 		# the current estimate in: yₜ = xₜβₜ + εₜ

	# these are needed to update β
	R::MatF     # pxp matrix
	q::Float64  # called Q in paper
	K::VecF     # px1 vector (equivalent to Kalman gain)

	yhat::Float64  #most recent estimate of y

	function OnlineFLS(p::Integer, δ::Real = 0.0001, wgt::Weighting = default(Weighting))

		# calculate the covariance matrix Vω from the smoothing parameter δ
		@assert δ > 0. && δ <= 1.
		μ = (1. - δ) / δ
		Vω = eye(p) / μ

		Vε = Variance(wgt)

		yvar = Variance(wgt)
		xvars = Variances(p, wgt)
		# xvars = [Variance(wgt) for i in 1:p]

		# create and init the object
		o = new(p, Vω, Vε, yvar, xvars)
		empty!(o)
		o
	end
end


function OnlineFLS(x::AVecF, y::Real, δ::Real = 0.0001, wgt::Weighting = default(Weighting))
	p = length(x)
	o = OnlineFLS(p, δ, wgt)
	update!(o, x, y)
	o
end

function OnlineFLS(x::AMatF, y::AVecF, δ::Real = 0.0001, wgt::Weighting = default(Weighting))
	p = size(x,2)
	o = OnlineFLS(p, δ, wgt)
	update!(o, x, y)
	o
end

#-----------------------------------------------------------------------# state

# nonzerostd(x) = if0then1(std(x))

# state vars: [normalizedBeta, rawBeta, Variance(y), Variance(x), std(ε), mostRecentEstimateOfY, nobs]
statenames(o::OnlineFLS) = [:βn, :β, :yvar, :xvars, :σε, :yhat, :nobs]
state(o::OnlineFLS) = Any[copy(o.β), o.β * std(o.yvar) ./ if0then1(std(o.xvars)), copy(o.yvar), copy(o.xvars), std(o.Vε), o.yhat, nobs(o)]

βn(o::OnlineFLS) = o.β
StatsBase.coef(o::OnlineFLS) = (o.β * std(o.yvar)) ./ if0then1(std(o.xvars))

#---------------------------------------------------------------------# update!


# NOTE: assumes x mat is (T x p), where T is the number of observations
# TODO: optimize
# function update!(o::OnlineFLS, x::AMatF, y::AVecF)
# 	@assert length(y) == size(x,1)
# 	for i in length(y)
# 		update!(o, row(x,i), y[i])
# 	end
# end

function update!(o::OnlineFLS, x::AVecF, y::Real)

	# standardize y and x
	y = standardize!(o.yvar, y)
	x = standardize!(o.xvars, x)

	# calc error and update error variance
	yhat = dot(x, o.β)
	ε = y - yhat
	update!(o.Vε, ε)

	# update sufficient stats to get the Kalman gain
	o.R += o.Vω - (o.q * o.K) * o.K'
	Rx = o.R * x
	o.q = dot(x, Rx) + var(o.Vε)
	o.K = Rx / if0then1(o.q)

	# @LOG ε var(o.Vε)
	# @LOG diag(o.R)
	# @LOG Rx
	# @LOG o.q
	# @LOG o.K

	# update β
	o.β += o.K * ε

	@DEBUG o.β

	# save the denormalized estimate of y
	o.yhat = unstandardize(o.yvar, yhat)

	o.n += 1
	return
end

# NOTE: keeps consistent p... just resets state
function Base.empty!(o::OnlineFLS)
	p = o.p
	empty!(o.Vε)
	o.n = 0
	o.β = zeros(p)

	# since Rₜ = Pₜ₋₁ + Vω, initialize with Vω
	o.R = copy(o.Vω)

	o.q = 0.
	o.K = zeros(p)
	o.yhat = 0.
end
# 
# function Base.merge!(o1::OnlineFLS, o2::OnlineFLS)
# 	error("not implemented")
# end
#
#
# function StatsBase.coeftable(o::OnlineFLS)
# 	error("not implemented")
# end
#
# function StatsBase.confint(o::OnlineFLS, level::Real = 0.95)
# 	error("not implemented")
# end

# predicts yₜ for a given xₜ
function StatsBase.predict(o::OnlineFLS, x::AVecF)
	unstandardize(o.yvar, dot(o.β, standardize(o.xvars, x)))
end

# NOTE: uses most recent estimate of βₜ to predict the whole matrix
function StatsBase.predict(o::OnlineFLS, x::AMatF)
	n = size(x,1)
	pred = zeros(n)
	for i in 1:n
		pred[i] = predict(o, row(x,i))
	end
	pred
end
