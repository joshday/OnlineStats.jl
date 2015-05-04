
# OLD: implementation similar to: https://github.com/kevinhughes27/pyIPCA/blob/master/pyIPCA/ccipca.py

# Based on Boutsidis et al: "Online Principal Component Analysis"

type OnlinePCA{W<:Weighting} <: OnlineStat
		L::MatF  # pca loading matrix
		d::Int  # number of input vars
    k::Int  # number of principal components
    n::Int
    weighting::W

    # needed for update
    e::Float64 	# ???
    U::MatF   	# d x k/e^3... init to zeros
    Z::MatF			# d x k/e^2... init to zeros
    w::Float64	#          ... init to 0.0
    wu::VecF 		# k/e^3 x 1... init to zeros
end


#---------------------------------------------------------------------# update!

# inputs:
#		X
#		k
#		e

function getFirstEig(A::MatF)
	eigvals, eigvecs = eig(A)
	
	# resort eigvals, eigvecs and return the first
	sortIndices = sortperm(eigvals, rev=true)
	λ = eigvals[sortIndices[1]]
	v = eigvecs[:, sortIndices[1]]
	λ, v
end


function update!(o::OnlinePCA, x::VecF)
	update_algo1!(o, x)
	# update_algo2!(o, x)
end


function update_algo1!(o::OnlinePCA, x::VecF)
	norm2x = ???  # TODO some constant? how to define?
	l = ceil(8k / e^2)
	ImUU = eye(d) - U * U'  		# d x d
	r = ImUU * x 								# d x 1
	C = ImUU * (Z * Z') * ImUU 	# d x d

	# fill in for each component
	while norm(C + r * r') >= max(w0, w) * k / e^2
		λ, u = getFirstEig(C)
	end

end

function update_algo2!(o::OnlinePCA, x::VecF)
	w0 = 0.0  # do we ever need to change this??
	w += sumabs2(x)
	ImUU = eye(d) - U * U'  		# d x d
	r = ImUU * x 								# d x 1
	C = ImUU * (Z * Z') * ImUU 	# d x d

	# fill in for each component
	while norm(C + r * r') >= max(w0, w) * k / e^2
		λ, u = getFirstEig(C)
	end

end
