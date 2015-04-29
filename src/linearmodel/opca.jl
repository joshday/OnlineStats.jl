
# implementation similar to: https://github.com/kevinhughes27/pyIPCA/blob/master/pyIPCA/ccipca.py


type OnlinePCA{W<:Weighting} <: OnlineStat
		L::Matrix{Float64}  # pca loading matrix
		k::Int  # number of input vars
    c::Int  # number of principal components
    n::Int
    weighting::W
end


#-----------------------------------------------------------------------------#
