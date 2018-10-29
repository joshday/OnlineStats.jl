# This file contains functions that test the accuracy of KahanSum, KahanMean,
# and KahanVariance.

# using Revise
# using OnlineStats
# using Statistics
# using Test


#-----------------------------------------------------------------------# The
# data A vector with few large values in the beginning and may tiny values in
# the end, basically the worst that can happen when summing up values one by
# one.
d = (rand(1_000_000) .^ 3) |> sort |> reverse;
d32 = Float32.(d);
l = length(d)

#-----------------------------------------------------------------------# KahanSum accuracy
function test_kahansum_accuracy(d::Array{T}) where T
    t = sum(d)

    # @show abs(t - foldr(+, d))
    # @show abs(t - foldl(+, d))
    # @show abs(t - sum(fit!(Sum(T), d)))
    # @show abs(t - sum(fit!(KahanSum(T), d)))

    sum_foldr     = abs(t - foldr(+, d))
    sum_foldl     = abs(t - foldl(+, d))
    sum_onlinesum = abs(t - sum(fit!(Sum(T), d)))
    sum_ks        = abs(t - sum(fit!(KahanSum(T), d)))
    @test sum_ks < sum_onlinesum
    @test sum_ks < sum_foldl
    @test sum_ks < sum_foldr
end
function test_kahansum_merge(d::Array{T}) where T
    l = length(d)
    @assert rem(l, 2) == 0

    ks = [ fit!(KahanSum(T), d[[i, (l ÷ 2) + i]])
           for i in 1:(l ÷ 2) ]

    naive_sum = foldl(+, sum.(ks))
    ks_fit = fit!(KahanSum(T), d) |> sum
    ks_foldr = foldr(merge!, deepcopy(ks), init = KahanSum(T)) |> sum
    ks_foldl = foldl(merge!, ks, init = KahanSum(T)) |> sum
    ks_reduce = reduce(merge!, ks, init = KahanSum(T)) |> sum
    j_sum = sum(d)

    # @show j_sum - naive_sum
    # @show j_sum - ks_fit
    # @show j_sum - ks_foldr
    # @show j_sum - ks_foldl
    # @show j_sum - ks_reduce

    naive_diff  = abs(j_sum - naive_sum)
    fit_diff    = abs(j_sum - ks_fit)
    foldr_diff  = abs(j_sum - ks_foldr)
    foldl_diff  = abs(j_sum - ks_foldl)
    reduce_diff = abs(j_sum - ks_reduce)

    @test naive_diff > fit_diff
    @test naive_diff > foldr_diff
    @test naive_diff > foldl_diff
    @test naive_diff > reduce_diff

    return nothing
end

@testset "KahanSum accuracy" begin
    test_kahansum_accuracy(d)
    test_kahansum_accuracy(d32)
    test_kahansum_merge(d)
    test_kahansum_merge(d32)
end


#-----------------------------------------------------------------------# KahanMean accuracy
function test_kahanmean_accuracy(d::Array{T}) where T
    t = mean(d)
    l = length(d)

    # @show abs(t - foldr(+, d) / l)
    # @show abs(t - foldl(+, d) / l)
    # if T == Float64
    #     @show abs(t - mean(fit!(Mean(), d)))
    # end
    # @show abs(t - mean(fit!(KahanMean(T), d)))

    mean_foldr      = abs(t - foldr(+, d) / l)
    mean_foldl      = abs(t - foldl(+, d) / l)
    mean_ks         = abs(t - mean(fit!(KahanMean(T), d)))
    if T == Float64
        mean_onlinemean = abs(t - mean(fit!(Mean(), d)))
        @test mean_ks < mean_onlinemean
    end
    @test mean_ks < mean_foldl
    @test mean_ks < mean_foldr
end
function test_kahanmean_merge(d::Array{T}) where T
    l = length(d)
    @assert rem(l, 2) == 0

    km = [ fit!(KahanMean(T), d[[i, (l ÷ 2) + i]])
           for i in 1:(l ÷ 2) ]
    if T == Float64
        m = [ fit!(Mean(), d[[i, (l ÷ 2) + i]])
              for i in 1:(l ÷ 2) ]
    end

    j_mean = mean(d)
    # this one is not a very high bar to beat!
    naive_mean = foldl(+, d) / length(d)
    # this one is much higher, but too tough!
    # naive_mean = foldr(+, mean.(km)) / length(km)
    if T == Float64
        m_fit = fit!(Mean(), d) |> mean
        m_foldr = foldr(merge!, deepcopy(m), init = Mean()) |> mean
        m_foldl = foldl(merge!,(m), init = Mean()) |> mean
        m_reduce = reduce(merge!,(m), init = Mean()) |> mean
    end
    km_fit = fit!(KahanMean(T), d) |> mean
    km_foldr = foldr(merge!, deepcopy(km), init = KahanMean(T)) |> mean
    km_foldl = foldl(merge!,(km), init = KahanMean(T)) |> mean
    km_reduce = reduce(merge!,(km), init = KahanMean(T)) |> mean

    # @show j_mean - naive_mean
    # if T == Float64
    #     @show j_mean - m_fit
    #     @show j_mean - m_foldr
    #     @show j_mean - m_foldl
    #     @show j_mean - m_reduce
    # end
    # @show j_mean - km_fit
    # @show j_mean - km_foldr
    # @show j_mean - km_foldl
    # @show j_mean - km_reduce

    naive_diff  = abs(j_mean - naive_mean)
    if T == Float64
        m_fit_diff    = abs(j_mean - m_fit)
        m_foldr_diff  = abs(j_mean - m_foldr)
        m_foldl_diff  = abs(j_mean - m_foldl)
        m_reduce_diff = abs(j_mean - m_reduce)
    end
    k_fit_diff    = abs(j_mean - km_fit)
    k_foldr_diff  = abs(j_mean - km_foldr)
    k_foldl_diff  = abs(j_mean - km_foldl)
    k_reduce_diff = abs(j_mean - km_reduce)

    if T == Float64
        @test m_fit_diff    > k_fit_diff
        @test_broken m_foldr_diff  > k_foldr_diff
        @test m_foldl_diff  > k_foldl_diff
        @test m_reduce_diff > k_reduce_diff
    end
    @test naive_diff > k_fit_diff
    @test naive_diff > k_foldr_diff
    @test naive_diff > k_foldl_diff
    @test naive_diff > k_reduce_diff

    return nothing
end

@testset "KahanMean accuracy" begin
    test_kahanmean_accuracy(d)
    test_kahanmean_accuracy(d32)

    test_kahanmean_merge(d)
    test_kahanmean_merge(d32)
end
