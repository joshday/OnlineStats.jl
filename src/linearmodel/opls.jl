
# OnlinePLS: Thomas Breloff (Cointegrated Technologies)


# implements an online partial least squares (OPLS) algorithm... modeled on Zeng et al (2014) [1]:
#		"Incremental partial least squares analysis of big streaming data"

# Method:
# There are 2 phases... model update and beta extraction.

# Model update is based on the goal of trying to maximize Cov(y, Xw) for some dx1 vector of weights w.
# i.e. we're looking for a linear combination of the X-components which produces high covariance with y.
# Taking the derivative of a Lagrange function gives us the solution w = Xᵀy / ‖Xᵀy‖
# Our online model updates the estimate of v := Xᵀy, and also tracks the decomposition of X using OnlinePCA
# in order to estimate the covariance matrix C := XᵀX/n, to reduce cpu/memory usage

# Note: we replace the update of v as in [1] with a smoothed version, which is correct for the exponential case,
# and approximately correct for the equal weighted case.
# proof summary for exponential weighting correctness: 
#		vₜ = ∑ᵗ [λ(1-λ)ᵗ⁻ⁱyᵢXᵢ]
#			 = λyₜXₜ + ∑ᵗ⁻¹ [λ(1-λ)ᵗ⁻¹⁻ⁱyᵢXᵢ]
#			 = λyₜXₜ + (1-λ)vₜ₋₁

# When the state is requested: "PLS projection directions are computed from a Gram-Schmidt orthonormalization
# of the Krylov sequence" [1]
# This gives us the weighting matrix W:
#		W := [v, Cv\{v}, C²v\{v,Cv}, ... Cᴷ⁻¹v\{v,Cv,...,Cᴷ⁻²v}]

# where "f/{g,h...} refers to the components of f that are orthogonal to the space spanned by {g,h,...}" [1]

#-------------------------------------------------------# Type and Constructors

type OnlinePLS <: OnlineStat
	d::Int  			# num dependent vars
	l::Int 				# num latent vars in OnlinePCA
	k::Int 				# num latent vars in PLS


	function OnlinePLS(p::Int, δ::Float64, wgt::Weighting = default(Weighting))
	end
end


function OnlinePLS(y::Float64, x::VecF, δ::Float64, wgt::Weighting = default(Weighting))
	# p = length(x)
	# o = OnlinePLS(p, δ, wgt)
	# update!(o, y, x)
	# o
end

function OnlinePLS(y::VecF, X::MatF, δ::Float64, wgt::Weighting = default(Weighting))
	# p = size(X,2)
	# o = OnlinePLS(p, δ, wgt)
	# update!(o, y, X)
	# o
end

#-----------------------------------------------------------------------# state

statenames(o::OnlinePLS) = [:nobs]
state(o::OnlinePLS) = Any[nobs(o)]


#---------------------------------------------------------------------# update!


# NOTE: assumes X mat is (T x p), where T is the number of observations
# TODO: optimize
function update!(o::OnlinePLS, y::VecF, X::MatF)
	@assert length(y) == size(X,1)
	for i in length(y)
		update!(o, y[i], vec(X[i,:]))
	end
end

function update!(o::OnlinePLS, y::Float64, x::VecF)


	o.n += 1
	return

end


function Base.empty!(o::OnlinePLS)
	# TODO
	o.n = 0
end

function Base.merge!(o1::OnlinePLS, o2::OnlinePLS)
	error("Merging undefined for PLS")
end


function StatsBase.coef(o::OnlinePLS)
	# TODO
end

function StatsBase.coeftable(o::OnlinePLS)
	# TODO
end

function StatsBase.confint(o::OnlinePLS, level::Float64 = 0.95)
	# TODO
end

# predicts yₜ for a given xₜ
function StatsBase.predict(o::OnlinePLS, x::VecF)
	# TODO
end

# NOTE: uses most recent estimate of βₜ to predict the whole matrix
function StatsBase.predict(o::OnlinePLS, X::MatF)
	n = size(X,1)
	pred = zeros(n)
	for i in 1:n
		pred[i] = StatsBase.predict(o, vec(X[i,:]))
	end
	pred
end


