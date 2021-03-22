### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 2d679c48-8af5-11eb-32fc-c9a76a667e61
begin
	using OnlineStats, Plots, Random
	theme(:lime)
end

# ╔═╡ 7ac57a82-8aff-11eb-0bbb-9fc037be9621
md"![](https://user-images.githubusercontent.com/8075494/111925031-87462b80-8a7d-11eb-98e2-eae044b13a3f.png)"

# ╔═╡ 497276a6-8af5-11eb-0d24-3d6c0c01c523
n = 100

# ╔═╡ 5ac71308-8af5-11eb-3767-2b7ef25271e1
nframes = 100

# ╔═╡ efb59472-8b03-11eb-17b7-d3c7960eb49f
begin 
	o = HeatMap(-5:.2:5, 0:.2:10)
	
	anim = @animate for i in 1:nframes 
		x = randn(5i)
		y = randexp(5i)
		fit!(o, zip(x,y))
		plot(o)
	end
	gif(anim, "temp.gif", fps=10)
end

# ╔═╡ Cell order:
# ╟─7ac57a82-8aff-11eb-0bbb-9fc037be9621
# ╟─2d679c48-8af5-11eb-32fc-c9a76a667e61
# ╠═497276a6-8af5-11eb-0d24-3d6c0c01c523
# ╠═5ac71308-8af5-11eb-3767-2b7ef25271e1
# ╠═efb59472-8b03-11eb-17b7-d3c7960eb49f
