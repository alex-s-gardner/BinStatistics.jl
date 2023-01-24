using BinStatistics
using DataFrames
using Statistics
using Test

@testset "BinStatistics.jl" begin
    df = DataFrame(x=1:10000, y=sin.(0.1:0.1:1000), v1 = cos.(0.1:0.1:1000), v2 = (1:10000).^2);
    
    df1 = binstats(df, :x, [1, 500, 5000, 10000], :v1)
    @test df1.nrow[1] == 499;

    df2 = binstats(df, [:x, :y], [[1, 500, 5000, 10000], [-1, -0.5, 0, 0.5, 1]], :v1)
    @test round(df2.v1_mean[3], digits = 10) == 0.0205146127
    @test ncol(df2) == 4
    @test nrow(df2) == 12

    df3 = binstats(df, [:x, :y], [[1, 5000, 10000], [-1, -0.5, 0, 0.5, 1]], [:v1, :v2], 
        grp_function = [], col_function = [mean, std])
    @test ncol(df3) == 4
    @test nrow(df3) == 8
    @test round(df3.v2_std[5], digits = -5) == 2.18e7

    df4 = binstats(df, ["x", "y"], [1:1000:10000, -1:0.01:1], [:v1, :v2], 
        grp_function = [], col_function = [mean std])
    @test ncol(df4) == 6
    @test nrow(df4) == 1716

    df5 = binstats(df, [:x, :y], [[1, 5000, 10000], [-1, -0.5, 0, 0.5, 1]], [:v1, :v2], 
               grp_function = [nrow, ncol], col_function = [mean std])
    @test ncol(df5) == 8
    @test nrow(df5) == 8 
    @test all(df5.x1.==4)     
end
