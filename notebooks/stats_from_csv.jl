### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 3edd0654-8b09-11eb-3687-836299a6af9b
using OnlineStats, Plots, CSV, Dates, PlutoUI

# ╔═╡ 0404234e-8b09-11eb-12f3-d5bd255db0ba
md"![](https://user-images.githubusercontent.com/8075494/111925031-87462b80-8a7d-11eb-98e2-eae044b13a3f.png)"

# ╔═╡ 38dc71c0-8b09-11eb-1ed9-dd16f0c7a8d7
md"""
# Statistics from CSV

In this example, we'll calculate some statistics from a 55-Million row CSV file.

[data source](https://www.kaggle.com/c/new-york-city-taxi-fare-prediction/overview)
"""

# ╔═╡ a530617c-8b0b-11eb-23ca-1b419843e4e5
file = "/Users/joshday/datasets/nyc_taxi_kaggle/train.csv"

# ╔═╡ d99058b4-8b0b-11eb-091d-058a779d4f0f
rows = CSV.Rows(file, reusebuffer=true)

# ╔═╡ 139bc94e-8b0e-11eb-1e52-f92dd6285603
begin
	o = GroupBy(String, Hist(0.0:100))
	
	itr = (row.passenger_count => parse(Float64, row.fare_amount) for row in rows)
	
	t = @elapsed fit!(o, itr)
	
	sort!(o)
	
	md"Seconds Elapsed: $(round(t, digits=2))"
end

# ╔═╡ 62c09e5c-8b0f-11eb-2bc6-3d6963b471c4
@bind val Select(collect(keys(o.value)))

# ╔═╡ 30833604-8b12-11eb-3227-cf3ae84d1395
plot(o.value[val], title=val)

# ╔═╡ Cell order:
# ╟─0404234e-8b09-11eb-12f3-d5bd255db0ba
# ╟─38dc71c0-8b09-11eb-1ed9-dd16f0c7a8d7
# ╠═3edd0654-8b09-11eb-3687-836299a6af9b
# ╠═a530617c-8b0b-11eb-23ca-1b419843e4e5
# ╠═d99058b4-8b0b-11eb-091d-058a779d4f0f
# ╠═139bc94e-8b0e-11eb-1e52-f92dd6285603
# ╠═62c09e5c-8b0f-11eb-2bc6-3d6963b471c4
# ╠═30833604-8b12-11eb-3227-cf3ae84d1395
