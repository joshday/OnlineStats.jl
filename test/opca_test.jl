
module OPCATEST

import OnlineStats

using FactCheck
# FactCheck.clear_results()  # TODO: remove

const ewgt = OnlineStats.ExponentialWeighting(500)

facts("OnlinePCA") do
	x = randn(10_000, 100)
	oc = OnlineStats.CovarianceMatrix(x)
	top5pca = pca(oc, 5, false)
	opca = OnlineStats.OnlinePCA(x', 5)
end

#-----------------------------------------------------------------------

function getsampledata_pca(n, d, k, σx, σpc)

	# "true" values for k principal components... scaled by 10, 9, ..., 1
	Z = (collect(k:-1:1) * σpc)' .* randn(n,k)
	Z = svd(Z)[1]  # ensure latent vectors are orthogonal
	Z = Z ./ std(Z,1)

	# "true" loading matrix
	V = rand(k, d)
	# V = ones(k,d)

	# generate sample X matrix built from k principal components and errors
	X = Z * V + σx * randn(n,d)

	V, Z, X
end

function getsampledata_pls(n, d, k, σx, σpc, σy)
	V, Z, X = getsampledata_pca(n, d, k, σx, σpc)

	# generate y from the last 2 columns of Z
	yV = rand(2)
	y = Z[:,end-1:end] * yV + σy * randn(n)

	V, Z, X, yV, y
end



#-----------------------------------------------------------------------

function dopca(X, k)
	pca = OnlineStats.OnlinePCA(X, k, ewgt)

	# I'm removing any remains of DataFrames...
	# It looks like this function isn't called anywhere.  Hopefully this doesn't mess
	# with your testing.
	# OnlineStats.tracedata(pca, 1, X)
end



function testpca(; n = 1000, d = 50, k = 10, σx = 0.3, σpc = 1.0)
	# check that a system exactly specified by X = ZV, when given X and the correct dimension k,
	# can produce an arbitrarily-scaled version of V and Z
	V, Z, X = getsampledata_pca(n, d, k, σx, σpc)
	pca = OnlineStats.OnlinePCA(X, k, ewgt)

	# regress each row of V on pca.V to find the "arbitrary scalars"
	# b = pca.V' \ V'
	b = Float64[(pca.V[i,:]' \ V[i,:]')[1] for i in 1:k]

	# find the error between the true and estimated V, as a pct of V
	err = (V - b .* pca.V) ./ V

	# check this error is small
	@fact norm(err) => roughly(0.0, atol=1e-10)  "testpca($σx, $k)"

	n, d, k, σx, σpc, V, Z, X, pca, b, err
end



function testpls(; n = 1000, d = 50, l = 20, k = 10, δ = 0.99, σx = 0.3, σpc = 1.0, σy = 1.0)

	V, Z, X, yV, y = getsampledata_pls(n, d, k, σx, σpc, σy)
	pls = OnlineStats.OnlinePLS(y, X, l, k, δ, ewgt)

	# TODO: tests
	yhat = OnlineStats.predict(pls, X)
	rng = n-100:n
	scatter(yhat[rng], y[rng])
end



#-----------------------------------------------------------------------

function dopca_checks()
	context("pca_checks") do

		# note: this should be almost exact
		testpca(σx = 0.0, k = 1)

		# note: this isn't very close... should it be??
		# testpca(σx = 0.0, k = 2)

	end
end


function dopls_checks()
	context("pls_checks") do

		# note: this should be almost exact
		testpls(σx = 0.0, k = 4)

	end
end




#-----------------------------------------------------------------------


function opca_test()

	facts("Test OnlinePCA") do


		# ***

		sev = OnlineStats.log_severity()
		OnlineStats.log_severity(OnlineStats.ERROR)  # turn off most logging


		dopca_checks()
		dopls_checks()


		# put logging back the way it was
		OnlineStats.log_severity(sev)

	end

	FactCheck.exitstatus()
end


end
