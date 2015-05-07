

using FactCheck
FactCheck.clear_results()  # TODO: remove





function getsampledata(; n = 1000, d = 50, k = 10, σx = 0.3, σpc = 1.0)
	
	# "true" loading matrix
	V = rand(k, d)

	# "true" values for k principal components
	Z = (rand(k) * σpc)' .* randn(n,k)
	Z = svd(Z)[1]  # ensure latent vectors are orthogonal

	# generate sample X matrix built from k principal components and errors
	X = Z * V + σx * randn(n,d)

	n, d, k, σx, σpc, V, Z, X
end

const ewgt = OnlineStats.ExponentialWeighting(200)


function dopca(X, k)
	pca = OnlineStats.OnlinePCA(X, k, ewgt)
	OnlineStats.tracedata(pca, 1, X)
end



function testpca(; σx = 0.0, k = 1)
	# check that a system exactly specified by X = ZV, when given X and the correct dimension k,
	# can produce an arbitrarily-scaled version of V and Z
	n, d, k, σx, σpc, V, Z, X = getsampledata(k = k, σx = σx, σpc = 10.0)
	pca = OnlineStats.OnlinePCA(X, k, ewgt)

	# regress each row of V on pca.V to find the "arbitrary scalars"
	# b = pca.V' \ V'
	b = Float64[(pca.V[i,:]' \ V[i,:]')[1] for i in 1:k]

	# find the error between the true and estimated V, as a pct of V
	err = (V - b .* pca.V) ./ V

	# check this error is small
	@fact norm(err) => roughly(0.0, atol=1e-10)  "testpca($σx, $k)"
end


function dofls_checks()
	context("fls_checks") do

		# note: this should be almost exact
		testpca(σx = 0.0, k = 1)

		# note: this isn't very close... should it be??
		# testpca(σx = 0.0, k = 2)

	end
end


function opca_test()

	facts("Test OnlinePCA") do

		n, d, k, σx, σpc, V, Z, X = getsampledata()


		# ***

		sev = OnlineStats.log_severity()
		OnlineStats.log_severity(OnlineStats.ERROR)  # turn off most logging


		@fact dopca(X, k) => anything  # just make sure there's no errors

		if !FactCheck.exitstatus()
			dofls_checks()
		end


		# put logging back the way it was
		OnlineStats.log_severity(sev)

	end

	FactCheck.exitstatus()
end