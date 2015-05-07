
# OnlinePLS: Thomas Breloff (Cointegrated Technologies)


# implements an online partial least squares (OPLS) algorithm... modeled on Zeng et al (2014) [1]:
#		"Incremental partial least squares analysis of big streaming data"



# Goal: We're looking for a linear combination of the X-components which produces high covariance with y.
# 			We then fit the reduced-dimension regression y = Zβ + e, where Z = XW has k columns of uncorrelated series.

# Reason:  If X has high multicolinearity between components, there will likely be overfitting
#					 problems for the model y = Xβ + e


# Method:
# There are 3 phases... model update, weight matrix extraction, and finally least squares fitting.


# Model update: 

# We are trying to maximize Cov(y, Xw) for some dx1 vector of weights w... 
#	this will approximate the loadings for the first latent vector.
# Taking the derivative of a Lagrange function gives us the solution w = Xᵀy / ‖Xᵀy‖
# Our online model updates the estimate of v := Xᵀy, and also tracks the decomposition of X using OnlinePCA
# in order to estimate the covariance matrix C := XᵀX/n, to reduce cpu/memory usage

# Note: we replace the update of v as in [1] with a smoothed version, which is correct for the exponential case,
# and approximately correct for the equal weighted case.
# proof summary for exponential weighting correctness: 
#		vₜ = ∑ᵗ [λ(1-λ)ᵗ⁻ⁱyᵢXᵢ]
#			 = λyₜXₜ + ∑ᵗ⁻¹ [λ(1-λ)ᵗ⁻¹⁻ⁱyᵢXᵢ]
#			 = λyₜXₜ + (1-λ)vₜ₋₁

# Weight matrix building:

# When the state is requested: "PLS projection directions are computed from a Gram-Schmidt orthonormalization
# of the Krylov sequence" [1]
# This gives us the weighting matrix W:
#		V := [v, Cv\{v}, C²v\{v,Cv}, ... Cᴷ⁻¹v\{v,Cv,...,Cᴷ⁻²v}]
#		W := [V₁/‖V₁‖, ..., Vₖ/‖Vₖ‖]

# where "f/{g,h...} refers to the components of f that are orthogonal to the space spanned by {g,h,...}" [1]


# Regression:

# Now that we have our weight matrix W, we can project X into a reduced dimensional space, 
#	and should get more robust regression results.
#		Z = XW
#		y = Zβ + e


# Summary:
# 	update v estimate
#		update OnlinePCA estimate (V) of first l pca vectors
#   build W matrix, and project Z = XW
#		regress y = Zβ + e
#		state = (v, V, W, β)


#-------------------------------------------------------# Type and Constructors

type OnlinePLS <: OnlineStat
	d::Int  			# num dependent vars
	l::Int 				# num latent vars in OnlinePCA
	k::Int 				# num latent vars in PLS

	v::VecF				# (d x 1) vector -- estimate of first column of 

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

	# update v1 and pca
	smooth!(o.v1, y * x, weight(o))
	update!(o.pca, x)

	# recompute W
	V = VecF[]
	W = VecF[]
	vi = copy(o.v1)
	w = copy(o.v1)
	for i in 1:o.k
		if i > 1
			# multiply Cw
			nextw = zeros(o.d)
			for j in 1:o.l
				pcaUj = row(o.pca.U, j)  # dx1 vector
				pcaVj = row(o.pca.V, j)	 # dx1 vector -- normalized -- eigenvector
				nextw += pcaUj * dot(pcaVj, w) / o.n  # TODO:  I don't like this n here... doesn't make sense with exponential weighting... how to change??
			end
		end

		# compute vi and add to V
		vi = copy(w)
		for j in 1:i-1
			vi -= vi .* V[j] .* V[j]
		end
		push!(V, vi)

		# add normalized vi to W
		push!(W, vi / norm(vi))
	end

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


