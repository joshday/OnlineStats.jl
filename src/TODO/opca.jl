#
# # OnlinePCA: Thomas Breloff (Cointegrated Technologies)
#
#
#
# # solving for a dimension-reduced Y = XV', where X (n x d) is the original data, and Y (n x k) is projected
# # V (k x d) is a matrix where the columns are the first k eigenvectors of X'X/n (the covariance of X)
# # e (k x 1) is a vector of eigenvectors of the covariance matrix
#
# # We compute e and V by incrementally updating e and U, where U is a (k x d) matrix with the properties:
# #		Uᵢ = iᵗʰ column of U
# #		Vᵢ = iᵗʰ column of V
# #			 = iᵗʰ eigenvector of X-covariance
# #			 = Uᵢ / ‖Uᵢ‖
# #		eᵢ = iᵗʰ eigenvalue of X-covariance
# #		   = ‖Uᵢ‖
#
# # note: V is the normalized version of U
#
# type OnlinePCA{W<:Weighting} <: OnlineStat
#
# 	d::Int  # number of input vars
#   k::Int  # number of principal components
#   weighting::W
#   n::Int
#
# 	U::MatF  # (k x d)
# 	V::MatF  # (k x d)
# 	e::VecF	 # (k x 1)
#   xmeans::Means{W}
#  end
#
# function OnlinePCA(d::Integer, k::Integer, wgt::Weighting = default(Weighting))
# 	OnlinePCA(d, k, wgt, 0, zeros(k,d), zeros(k,d), zeros(k), Means(d, wgt))
# end
#
#
# function OnlinePCA(x::AVecF, k::Integer, wgt::Weighting = default(Weighting))
# 	o = OnlinePCA(length(x), k, wgt)
# 	update!(o, x)
# 	o
# end
#
# function OnlinePCA(X::AMatF, k::Integer, wgt::Weighting = default(Weighting))
# 	o = OnlinePCA(ncols(X), k, wgt)
# 	update!(o, X)
# 	o
# end
#
#
#
# #-----------------------------------------------------------------------# state
#
# statenames(o::OnlinePCA) = [:U, :V, :e, :xmeans, :nobs]
# state(o::OnlinePCA) = Any[copy(o.U), copy(o.V), copy(o.e), copy(mean(o.xmeans)), nobs(o)]
#
#
# #---------------------------------------------------------------------# update!
#
# # TODO: roughly based on Weng et al (2003): "Candid covariance-free incremental principal component analysis"
# # used https://github.com/kevinhughes27/pyIPCA/blob/master/pyIPCA/ccipca.py as a reference
#
#
# # TODO: optimize, potentially by using view(X, ...) instead of X[...]
#
# function update!(o::OnlinePCA, x::AVecF)
#
# 	x = center!(o.xmeans, x)
# 	λ = weight(o)
#
# 	@inbounds for i in 1:min(o.k, o.n)
#
# 		if o.e[i] == 0. # this should be more robust than checking i == o.n
#
# 			# initialize ith principal component
# 			Ui = x
# 			ei = norm(Ui)
# 			Vi = Ui / ei
#
# 		else
#
# 			# update the ith eigvec/eigval
# 			Ui = row(o.U, i)
# 			smooth!(Ui, x * (dot(x, Ui) / o.e[i]), λ)
# 			ei = norm(Ui)
# 			Vi = Ui / ei
#
# 			# subtract projection on ith PC
# 			x -= dot(x, Vi) * Vi
#
# 		end
#
# 		# store these updates
# 		row!(o.U, i, Ui)
# 		row!(o.V, i, Vi)
# 		o.e[i] = ei
# 	end
#
# 	o.n += 1
# 	nothing
# end
#
#
# # function update!(o::OnlinePCA, X::AMatF)
# # 	for i in 1:nrows(X)
# # 		update!(o, row(X,i))
# # 	end
# # end
#
#
#
# function Base.empty!(o::OnlinePCA)
# 	o.U = zeros(o.k, o.d)
# 	o.V = zeros(o.k, o.d)
# 	o.e = zeros(o.k)
# 	o.n = 0
# 	o.xmeans = Means(o.d, o.weighting)
# 	nothing
# end
#
# function Base.merge!(o1::OnlinePCA, o2::OnlinePCA)
# 	error("Merging undefined for PCA")
# end
#
#
# # returns a vector z = Vx
# StatsBase.predict(o::OnlinePCA, x::AVecF) = o.V * center(o.xmeans, x)
#
# function StatsBase.predict(o::OnlinePCA, X::AMatF)
# 	n = size(X,1)
# 	Z = zeros(n, o.k)
# 	for i in 1:n
# 		row!(Z, i, predict(o, row(X,i)))
# 	end
# 	Z
# end
