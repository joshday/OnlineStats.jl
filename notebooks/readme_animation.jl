### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 2d679c48-8af5-11eb-32fc-c9a76a667e61
using OnlineStats, Plots

# ╔═╡ 497276a6-8af5-11eb-0d24-3d6c0c01c523
n = 1000

# ╔═╡ 5ac71308-8af5-11eb-3767-2b7ef25271e1
nframes = 10

# ╔═╡ e36eda12-8af8-11eb-3295-598adeb2d349
plot(fit!(Partition(KHist(10), 50), randn(10^5)))

# ╔═╡ 80d221d2-8af5-11eb-1c96-7b814e0497ab
begin
	o = Partition(KHist(10), 50)
	
	@gif for i in 1:nframes 
		x = randn(n)
		y = x + randn(n)
		fit!(o, y)
		plot(o)
	end
end

# ╔═╡ Cell order:
# ╠═2d679c48-8af5-11eb-32fc-c9a76a667e61
# ╠═497276a6-8af5-11eb-0d24-3d6c0c01c523
# ╠═5ac71308-8af5-11eb-3767-2b7ef25271e1
# ╠═e36eda12-8af8-11eb-3295-598adeb2d349
# ╠═80d221d2-8af5-11eb-1c96-7b814e0497ab
