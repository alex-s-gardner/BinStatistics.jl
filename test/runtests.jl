using BinStatistics
using DataFrames
using Statistics
using Test

@testset "BinStatistics.jl" begin
    df = DataFrame(x=sin.(0:0.01:100), y = cos.(0:0.01:100), v1 = 0:0.01:100, v2 = (0:0.01:100).^2);
    
    df1 = binstats(df, [:x], [[-1, -.5, -0.25, 1]], [:v1])
    @test df1.nrow[2] == 841;

    df2 = binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1])
    @test round(df2.v1_mean[3], digits = 10) == 50.7116589862
    @test round(ncol(df2)) == 4
    @test round(nrow(df2)) == 7

    df3 = binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], 
        grp_functions = [], col_functions = [mean, std])
    @test round(ncol(df3)) == 4
    @test round(nrow(df3)) == 7
    @test isnan(df3.v2_std[5])

    df4 = binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], 
        grp_functions = [], col_functions = [mean std])
    @test round(ncol(df4)) == 6
    @test round(nrow(df4)) == 7

    df5 = binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], 
               grp_functions = [nrow, ncol], col_functions = [mean std])
    @test round(ncol(df5)) == 8
    @test round(nrow(df5)) == 7  
    @test all(df5.x1.==4)     
end
