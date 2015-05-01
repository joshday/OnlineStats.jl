

using FactCheck



function getsampledata(; n = 1000, p = 10, σx = 0.3, σy = 1.0, σβ = 0.01)
	
	# generate independent series and errors
	dX = σx * randn(n,p)				# independent vars  (nxp)
	# cumsum!(X, X)
	ε = σy * randn(n)		# errors

	# create a time varying βₜ = βₜ₋₁ + ωₜ
	β = σβ * randn(n,p)
	β[1,:] = rand(p)      # β₀ is random uniforms
	cumsum!(β, β)   			# now do the cumulative sum with β₀ as the starting vector

	# now create the dependent series
	dy = vec(sum(dX .* β, 2)) + ε   # dependent

	n, p, dy, dX, ε, β
end

function ofls_test()
	facts("Test OnlineFLS") do

		n, p, y, X, ε, β = getsampledata()

		@fact size(y) => (n,)
		@fact size(X) => (n,p)
		@fact size(β) => (n,p)

		# ***

		# # this doesn't really belong here as is:
		# # lets do the OFLS fit
		# fls = OnlineStats.OnlineFLS(p, 0.0001, OnlineStats.ExponentialWeighting(200))
		# df = tracedata(fls, 1, y, X)

		# # do a plot of y vs yhat (need to change this to match your plotting package...
		# # I have a custom plotting package that is not currently open source, but may be eventually)
		# plot([y OnlineStats.getnice(df, :yhat)])

	end

	FactCheck.exitstatus()
end