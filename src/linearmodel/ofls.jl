
# implements the online flexible least squares algorithm... modeled on Montana et al (2009):
#   "Flexible least squares for temporal data mining and statistical arbitrage"


#-------------------------------------------------------# Type and Constructors

type OnlineFLS{W<:Weighting} <: VectorStat
	p::Int  # number of independent vars
	weighting::W
	n::Int
	β::VecF # the current estimate in: yₜ = Xₜβₜ + εₜ

	# these are needed to update β
	Vω::MatF    # pxp (const) covariance matrix of Δβₜ
	Vε::Float64 # (const) variance of error term
	R::MatF     # pxp matrix
	q::Float64  # called Q in paper
	K::VecF     # px1 vector (equivalent to Kalman gain)
	# P::MatF     # pxp matrix

	# construct a fresh object for a given p/wgt
	function OnlineFLS(p::Int, wgt::Weighting = default(Weighting))
		o = new(p, wgt)
		empty!(o)
		o
	end
end

# TODO constructors to setup problem





#-----------------------------------------------------------------------# state

statenames(o::OnlineFLS) = [:β, :nobs]
state(o::OnlineFLS) = [β(o), nobs(o)]

β(o::OnlineFLS) = o.β
Base.beta(o::OnlineFLS) = o.β

#---------------------------------------------------------------------# update!

# NOTE: assumes X mat is (p x T), where T is the number of observations
# NOTE: Julia has column-major matrices, which means that accessing the data one column at a time will be faster.
# 			We should think about using ArrayViews or similar when optimizing
function update!(o::OnlineFLS, y::VecF, X::MatF)
	@assert length(y) == size(X,2)
	for i in length(y)
		update!(o, y[i], X[:,i])
	end
end

function update!(o::OnlineFLS, y::Float64, x::VecF)
	
	# update Kalman gain
	# o.R = o.P + o.Vω
	o.R += o.Vε - (o.q * o.K) * o.K'
	Rx = o.R * x
	o.q = dot(x, Rx)
	o.K = Rx / o.Q

	# update β
	ε = y - dot(x, o.β)
	o.β += o.K * ε

	# finish
	# o.P = o.R - (o.q * o.K) * o.K'
	o.n += 1
	return

end

Base.copy(o::OnlineFLS) = OnlineFLS(copy(o.β), o.p, o.n, o.weighting, copy(o.Vω), o.Vε, copy(o.R), o.q, copy(o.K)) #, copy(o.P))

# NOTE: keeps consistent p... just resets state
function Base.empty!(o::OnlineFLS)
	p = o.p
	o.n = 0
	o.β = zeros(p)
	o.Vω = zeros(p,p)
	o.Vε = 0.
	o.R = zeros(p,p)
	o.q = 0.
	o.K = zeros(p)
	# o.P = zeros(p,p)
end

function Base.merge!(o1::OnlineFLS, o2::OnlineFLS)
	# TODO
end