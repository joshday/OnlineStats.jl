
module OFLSTest

using OnlineStats
using FactCheck

# using Qwt


function getsampledata(; n = 1000, p = 10, σx = 0.3, σy = 1.0, σβ = 0.01)

	# generate independent series and errors
	dx = σx * randn(n,p)				# independent vars  (nxp)
	ε = σy * randn(n)		# errors

	# create a time varying βₜ = βₜ₋₁ + ωₜ
	β = σβ * randn(n,p)
	β[1,:] = 10*rand(p)      # β₀ is random uniforms
	cumsum!(β, β, 1)   			# now do the cumulative sum with β₀ as the starting vector

	# now create the dependent series
	dy = vec(sum(dx .* β, 2)) + ε   # dependent

	n, p, dy, dx, ε, β
end

function dofls(p, x, y)
	fls = OnlineFLS(p, 0.0001, OnlineStats.ExponentialWeighting(500))
	βhat = Any[]
	yhat = Float64[]
	for i in 1:length(y)
		xrow = OnlineStats.row(x,i)
		update!(fls, xrow, y[i])
		push!(βhat, coef(fls))
		push!(yhat, predict(fls, xrow))
	end
	fls, βhat, yhat
end


# sev = OnlineStats.log_severity()
# OnlineStats.log_severity!(OnlineStats.ErrorSeverity)  # turn off most logging


facts("Test OnlineFLS") do

	n, p, y, x, ε, β = getsampledata()

	@fact size(y) --> (n,)
	@fact size(x) --> (n,p)
	@fact size(β) --> (n,p)
	dofls(p, x, y)  # just make sure there's no errors


	σx = 2.0
	n, p, y, x, ε, β = getsampledata(σx = σx)
	fls, βhat, yhat = dofls(p, x, y)

	@fact size(βhat,1) --> n
	@fact size(yhat,1) --> n
	@fact std(fls.xvars) --> roughly(fill(σx,p), atol = 0.7)

	r2 = 1 - var(y-yhat) / var(y)
	@fact r2 --> greater_than(0.9)
	@fact vec(β[n,:]) --> roughly(βhat[end], atol = 0.7)


	# # # do a plot of y vs yhat (need to change this to match your plotting package...
	# # # I have a custom plotting package that is not currently open source, but may be eventually)
	# plt1 = plot([y yhat], show=false, labels=["y","yhat"])
	# plt2 = subplot(β, show=false, labels=["β$i" for i in 1:p])
	# for i in 1:p
	# 	βhatᵢ = Float64[x[i] for x in βhat]
	# 	oplot(plt2.plots[i], βhatᵢ, label="βhat$i")
	# end
	# global window
	# window = vsplitter(plt1,plt2)
 	# moveToLastScreen(window)
 	# showwidget(window)

end

# # put logging back the way it was
# OnlineStats.log_severity!(sev)

end # module
