

using FactCheck
FactCheck.clear_results()  # TODO: remove





function getsampledata(; n = 1000, d = 50, k = 10, σx = 0.3, σpc = 1.0)
	
	# "true" loading matrix
	V = rand(k, d)

	# random series for k principal components
	PC = (rand(k) * σpc) .* randn(n,k)
	# PC = qr(PC)[1]  # do a qr factorization to ensure PC are orthogonal to each other
	PC = svd(PC)[1]

	# generate series built from k principal components and errors
	dX = PC * V + σx * randn(n,d)
	# e = σe * randn(n)		# errors

	n, d, k, σx, σpc, V, PC, dX
end

function dopca(X, k)
	pca = OnlineStats.OnlinePCA(X, k, OnlineStats.ExponentialWeighting(200))
	OnlineStats.tracedata(pca, 1, X)
end

function dofls_checks()
	context("fls_checks") do
		σx = 2.0
		n, d, k, σx, σpc, V, PC, dX = getsampledata(σx = σx)
		df = dopca(X, k)
		@fact size(df,1) => n

		# context("check final σx") do
		# 	for sxi in df[:xvars][end]
		# 		@fact std(sxi) => roughly(σx, rtol=0.2)
		# 		# @fact abs(std(sxi)/σx-1)  => less_than(0.2)
		# 	end
		# end

		# r2 = 1 - var(y-OnlineStats.getnice(df,:yhat)) / var(y)
		# @fact r2 => greater_than(0.8)

		# βhat = OnlineStats.getnice(df, :β)[end,:]
		# context("check β") do
		# 	for i in 1:k
		# 		@fact β[end,i] => roughly(βhat[i], rtol=0.3)
		# 	end
		# end

		# endsz = 20
		# rng = n-endsz+1:n
		# @fact sumabs2(y[rng] - OnlineStats.getnice(df,:yhat)[rng]) / endsz => less_than(0.1 * mean(abs(y[rng])))
	end
end


function opca_test()

	facts("Test OnlinePCA") do

		n, d, k, σx, σpc, V, PC, dX = getsampledata()

		# @fact size(y) => (n,)
		# @fact size(X) => (n,k)
		# @fact size(β) => (n,k)

		# ***

		sev = OnlineStats.log_severity()
		OnlineStats.log_severity(OnlineStats.ERROR)  # turn off most logging

		# df = dopca(X, k)
		# @fact df => anything
		@fact dopca(X, k) => anything  # just make sure there's no errors

		if !FactCheck.exitstatus()
			dofls_checks()
		end

		# # this doesn't really belong here as is:
		# # lets do the OFLS fit
		# pca = OnlineStats.OnlinePCA(k, 0.0001, OnlineStats.ExponentialWeighting(200))
		# df = tracedata(pca, 1, y, X)

		# # do a plot of y vs yhat (need to change this to match your plotting package...
		# # I have a custom plotting package that is not currently open source, but may be eventually)
		# plot([y OnlineStats.getnice(df, :yhat)])

		# put logging back the way it was
		OnlineStats.log_severity(sev)

	end

	FactCheck.exitstatus()
end