
# implementation similar to: https://github.com/kevinhughes27/pyIPCA/blob/master/pyIPCA/ccipca.py


type IPCA{W<:Weighting} <: OnlineStat
		L::Matrix{Float64}  # pca loading matrix
		k::Int  # number of input vars
    c::Int  # number of principal components
    n::Int
    weighting::W
end


#-----------------------------------------------------------------------------#

# function update!(obj::IPCA, y::Vector)
#     for yi in y
#         update!(obj, yi)
#     end
# end

function update!(obj::IPCA, y::Vector{Float64})
	# TODO
	for i in 1:c
		# update the ith loading
	end
end



#-----------------------------------------------------------------------------#

function Base.copy(obj::IPCA)
	# TODO
end

function Base.empty!(obj::IPCA)
	# TODO
end

#-----------------------------------------------------------------------------#

Base.string(obj::IPCA) = "IPCA{n=$(nobs(obj)), c=$(obj.c)}"
Base.show(io::IO, obj::IPCA) = show(io, string(obj))

#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#