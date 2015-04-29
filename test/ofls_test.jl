

using FactCheck


function getsampledata(; n = 1000, p = 10, σₑ = 0.1, σ = 0.01)
	
	# generate independent series and errors
	X = randn(n,p)				# independent vars  (nxp)
	cumsum!(X, X)
	e = σₑ * randn(n)		# errors

	# create a time varying β
	β = σ * randn(n,p)
	β[1,:] = rand(p)      # β₀ is random uniforms
	cumsum!(β, β)   			# now do the cumulative sum with β₀ as the starting vector

	# now create the dependent series
	y = 5.0 + vec(sum(X .* β, 2)) + e   # dependent

	n, p, y, X, e, β
end

function ofls_test()
	facts("Test OnlineFLS") do

		n, p, y, X, e, β = getsampledata()

		@fact size(y) => (n,)
		@fact size(X) => (n,p)
		@fact size(β) => (n,p)

		# lets do the OFLS fit for δ == 1 (i.e. should be constant βₜ)
		fls = OnlineFLS(p, 1.0)
		df = tracedata(fls, y, X)

	end
end