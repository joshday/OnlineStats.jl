

using FactCheck
FactCheck.clear_results()  # TODO: remove


function getsampledata(; n = 1000, p = 10, σx = 0.3, σy = 1.0, σβ = 0.01)
	
	# generate independent series and errors
	dX = σx * randn(n,p)				# independent vars  (nxp)
	# cumsum!(X, X)
	ε = σy * randn(n)		# errors

	# create a time varying βₜ = βₜ₋₁ + ωₜ
	β = σβ * randn(n,p)
	β[1,:] = 10*rand(p)      # β₀ is random uniforms
	cumsum!(β, β)   			# now do the cumulative sum with β₀ as the starting vector

	# now create the dependent series
	dy = vec(sum(dX .* β, 2)) + ε   # dependent

	n, p, dy, dX, ε, β
end

function dofls(p, y, X)
	fls = OnlineStats.OnlineFLS(p, 0.0001, OnlineStats.ExponentialWeighting(200))
	OnlineStats.tracedata(fls, 1, y, X)
end

function dofls_checks()
	context("fls_checks") do
		σx = 2.0
		n, p, y, X, ε, β = getsampledata(σx = σx)
		df = dofls(p, y, X)
		@fact size(df,1) => n

		context("check final σx") do
			for sxi in df[:xvars][end]
				@fact std(sxi) => roughly(σx, rtol=0.2)
				# @fact abs(std(sxi)/σx-1)  => less_than(0.2)
			end
		end

		r2 = 1 - var(y-OnlineStats.getnice(df,:yhat)) / var(y)
		@fact r2 => greater_than(0.8)

		βhat = OnlineStats.getnice(df, :β)[end,:]
		context("check β") do
			for i in 1:p
				@fact β[end,i] => roughly(βhat[i], rtol=0.3)
			end
		end

		# endsz = 20
		# rng = n-endsz+1:n
		# @fact sumabs2(y[rng] - OnlineStats.getnice(df,:yhat)[rng]) / endsz => less_than(0.1 * mean(abs(y[rng])))
	end
end


function ofls_test()

	facts("Test OnlineFLS") do

		n, p, y, X, ε, β = getsampledata()

		@fact size(y) => (n,)
		@fact size(X) => (n,p)
		@fact size(β) => (n,p)

		# ***

		sev = OnlineStats.log_severity()
		OnlineStats.log_severity(OnlineStats.ERROR)  # turn off most logging

		df = dofls(p,y,X)
		@fact df => anything
		@fact dofls(p, y, X) => anything  # just make sure there's no errors

		if !FactCheck.exitstatus()
			dofls_checks()
		end

		# # this doesn't really belong here as is:
		# # lets do the OFLS fit
		# fls = OnlineStats.OnlineFLS(p, 0.0001, OnlineStats.ExponentialWeighting(200))
		# df = tracedata(fls, 1, y, X)

		# # do a plot of y vs yhat (need to change this to match your plotting package...
		# # I have a custom plotting package that is not currently open source, but may be eventually)
		# plot([y OnlineStats.getnice(df, :yhat)])

		# put logging back the way it was
		OnlineStats.log_severity(sev)

	end

	FactCheck.exitstatus()
end