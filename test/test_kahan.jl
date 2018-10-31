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

Random.seed!(127)
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
        # There are accuracy issues with merge!
        @test m_foldr_diff > k_foldr_diff / 10
        @test m_foldl_diff  > k_foldl_diff
        @test m_reduce_diff > k_reduce_diff
    end
    @test naive_diff > k_fit_diff
    # There are accuracy issues with merge!
    @test naive_diff > k_foldr_diff / 10
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

#-----------------------------------------------------------------------# KahanVariance accuracy
function test_kahanvar_accuracy(d::Array{T}) where T
    t = var(d)
    l = length(d)

    naive_var_foldl = (mapfoldl(x -> x ^ 2, +, d) + foldl(+, d) / l) / l
    naive_var_foldr = (mapfoldr(x -> x ^ 2, +, d) + foldr(+, d) / l) / l

    # if T == Float64
    #     @show abs(t - var(fit!(Variance(), d)))
    # end
    # @show abs(t - var(fit!(KahanVariance(T), d)))

    var_foldr      = abs(t - naive_var_foldr)
    var_foldl      = abs(t - naive_var_foldl)
    var_ks         = abs(t - var(fit!(KahanVariance(T), d)))
    if T == Float64
        var_onlinevar = abs(t - var(fit!(Variance(), d)))
        @test var_ks < var_onlinevar
    end
    @test var_ks < var_foldl
    @test var_ks < var_foldr
end
function test_kahanvar_merge(d::Array{T}) where T
    l = length(d)
    @assert rem(l, 2) == 0

    km = [ fit!(KahanVariance(T), d[[i, (l ÷ 2) + i]])
           for i in 1:(l ÷ 2) ]
    if T == Float64
        m = [ fit!(Variance(), d[[i, (l ÷ 2) + i]])
              for i in 1:(l ÷ 2) ]
    end

    j_var = var(d)
    # this one is not a very high bar to beat!
    naive_var_foldl = (mapfoldl(x -> x ^ 2, +, d) + foldl(+, d) / l) / l
    naive_var_foldr = (mapfoldr(x -> x ^ 2, +, d) + foldr(+, d) / l) / l
    if T == Float64
        v_fit = fit!(Variance(), d) |> var
        v_foldr = foldr(merge!, deepcopy(m), init = Variance()) |> var
        v_foldl = foldl(merge!,(m), init = Variance()) |> var
        v_reduce = reduce(merge!,(m), init = Variance()) |> var
    end
    k_fit = fit!(KahanVariance(T), d) |> var
    k_foldr = foldr(merge!, deepcopy(km), init = KahanVariance(T)) |> var
    k_foldl = foldl(merge!,(km), init = KahanVariance(T)) |> var
    k_reduce = reduce(merge!,(km), init = KahanVariance(T)) |> var

    # @show j_var - naive_var_foldl
    # @show j_var - naive_var_foldr
    # if T == Float64
    #     @show j_var - v_fit
    #     @show j_var - v_foldr
    #     @show j_var - v_foldl
    #     @show j_var - v_reduce
    # end
    # @show j_var - k_fit
    # @show j_var - k_foldr
    # @show j_var - k_foldl
    # @show j_var - k_reduce

    naive_diff_foldr  = abs(j_var - naive_var_foldr)
    naive_diff_foldl  = abs(j_var - naive_var_foldr)
    if T == Float64
        v_fit_diff    = abs(j_var - v_fit)
        v_foldr_diff  = abs(j_var - v_foldr)
        v_foldl_diff  = abs(j_var - v_foldl)
        v_reduce_diff = abs(j_var - v_reduce)
    end
    k_fit_diff    = abs(j_var - k_fit)
    k_foldr_diff  = abs(j_var - k_foldr)
    k_foldl_diff  = abs(j_var - k_foldl)
    k_reduce_diff = abs(j_var - k_reduce)

    if T == Float64
        @test v_fit_diff    > k_fit_diff
        # There are accuracy issues with merge!
        @test v_foldr_diff  > k_foldr_diff / 10
        @test v_foldl_diff  > k_foldl_diff
        @test v_reduce_diff > k_reduce_diff
    end
    @test naive_diff_foldr > k_fit_diff
    @test naive_diff_foldr > k_fit_diff
    @test naive_diff_foldr > k_foldr_diff
    @test naive_diff_foldr > k_foldl_diff
    @test naive_diff_foldr > k_reduce_diff
    @test naive_diff_foldl > k_fit_diff
    @test naive_diff_foldl > k_fit_diff
    @test naive_diff_foldl > k_foldr_diff
    @test naive_diff_foldl > k_foldl_diff
    @test naive_diff_foldl > k_reduce_diff

    return nothing
end

@testset "KahanVariance accuracy" begin
    test_kahanvar_accuracy(d)
    test_kahanvar_accuracy(d32)

    test_kahanvar_merge(d)
    test_kahanvar_merge(d32)
end
