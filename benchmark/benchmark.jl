# add and load packages
using Pkg
Pkg.add(PackageSpec(name="PyCall", rev="master"))
Pkg.build("PyCall")
using PyCall
sp = pyimport("scipy.stats")
Pkg.add(url="https://github.com/alex-s-gardner/BinStatistics.jl#main")
Pkg.add("DataFrames")
Pkg.add("Statistics")
Pkg.add("BenchmarkTools")
using BinStatistics
using DataFrames
using Statistics
using BenchmarkTools

# make synthetic data
n = 1000000;
df = DataFrame();
df.x = rand(n).*20;
df.y = rand(n).*20;
df.v1 = cos.(df.x) .+ randn(n)*3;
df.v2 = cos.(df.x .- df.y) .+ sin.(df.x .+ df.y) .+ randn(n)*3;
df.v3 = df.v1 .+ df.v2;

# benchmark against binned_statistic
@btime foo = sp.binned_statistic(df.x, df.v1, statistic="mean", bins=collect(0:0.1:20));
@btime df1 = binstats(df, :x, 0:0.1:20, :v1, grp_function = []);

@btime foo = sp.binned_statistic(df.x, df.v1, statistic="median", bins=collect(0:0.1:20));
@btime df1 = binstats(df, :x, 0:0.1:20, :v1, grp_function = [], col_function = [median]);

@btime foo = sp.binned_statistic(df.x, df.v1, statistic="max", bins=collect(0:0.1:20));
@btime df1 = binstats(df, :x, 0:0.1:20, :v1, grp_function = [], col_function = [maximum]);

# benchmark against binned_statistic_2d
@btime foo = sp.binned_statistic_2d(df.x, df.y, df.v1, statistic="mean", bins=[collect(0:0.1:20), collect(0:0.1:20)]);
@btime df1 = binstats(df, :x, 0:0.1:20, grp_function = [], :v1);

@btime foo = sp.binned_statistic_2d(df.x, df.y, df.v1, statistic="median", bins=[collect(0:0.1:20), collect(0:0.1:20)]);
@btime df1 = binstats(df, :x, 0:0.1:20, :v1, grp_function = [], col_function = [median]);

@btime foo = sp.binned_statistic_2d(df.x, df.y, df.v1, statistic="max", bins=[collect(0:0.1:20), collect(0:0.1:20)]);
@btime df1 = binstats(df, :x, 0:0.1:20, :v1, grp_function = [], col_function = [maximum]);

# statistics on multiple variables 

@btime begin
    foo1 = sp.binned_statistic(df.x, df.v1, statistic="mean", bins=collect(0:0.1:20));
    foo2 = sp.binned_statistic(df.x, df.v2, statistic="mean", bins=collect(0:0.1:20));
end
@btime df1 = binstats(df, :x, 0:0.1:20, [:v1, :v2], grp_function = []);

@btime begin
    foo1 = sp.binned_statistic(df.x, df.v1, statistic="median", bins=collect(0:0.1:20));
    foo2 = sp.binned_statistic(df.x, df.v2, statistic="median", bins=collect(0:0.1:20));
end
@btime df1 = binstats(df, :x, 0:0.1:20, [:v1, :v2], grp_function = [], col_function = [median]);
