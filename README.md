# BinStatistics.jl
Highly generic and efficient computation of n-dimensional binned statistic(s) for n-variable(s)

BinStatistics provides the `binstats` function that is build on top of `DataFrames.jl` 
and `CatagoricalArrays.jl`

## binstats function
```julia
"""
    binstats(df, axis_col, axis_edges, bin_col; 
        grp_function = [nrow], col_function = [mean], missing_bin = false)
    
Returns a DataFrame containing function values for binned variables of `df`.

# Arguments
- `axis_col`: binning axes column(s)
- `axis_edges`: bin edges for axes column(s) `axis_col`
- `bin_col`: column(s) to be binned
- `grp_function = [nrow]`: column independent funciton(s) to be applied at group level
- `var_function = [mean]`: column dependent funciton(s) to be applied to `bin_col` at group level
- `missing_bin = false`: include missing bins
"""
```

## Examples

### load packages
```julia

using BinStatistics
using DataFrames
using CairoMakie
using Statistics
```

### make synthetic data
```julia
begin
    n = 1000000;
    df = DataFrame();
    df.x = rand(n).*20;
    df.y = rand(n).*20;
    df.v1 = cos.(df.x) .+ randn(n)*3;
    df.v2 = cos.(df.x .- df.y) .+ sin.(df.x .+ df.y) .+ randn(n)*3;
    df.v3 = df.v1 .+ df.v2;
end
```

### calculate `count/nrow` and mean of `v1` binned according to `x`
```julia
df1 = binstats(df, :x, 0:0.1:20, :v1)
```
![binstats example 1](https://github.com/alex-s-gardner/BinStatistics.jl/assets/images/1.png?raw=true)

plotting block
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], bincenter.(df1[:,1]), df1.v1_mean)  
    fig
end

### calculate `count/nrow` and `medain` of `v1` and `v3` binned according to `x`
```julia
df2 = binstats(df, :x, 0:0.1:20, ["v1", "v2"])
```

plotting block
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], bincenter.(df2[:,1]), df2.v1_mean, label = "v1")
    scatter!(fig[1, 2], bincenter.(df2[:,1]), df2.v2_mean, label = "v2")
    axislegend()
    fig
end


### calculate `count/nrow`, `mean`, `medain` and `std` of `v1` binned according to `x`
```julia
df3 = binstats(df, :x, 0:0.1:20, :v1; col_function = [mean, median, std])
```

plotting block
begin
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], bincenter.(df3[:,1]), df3.v1_mean, label = "mean")
    scatter!(fig[1, 2], bincenter.(df3[:,1]), df3.v1_median, label = "median")
    scatter!(fig[1, 2], bincenter.(df3[:,1]), df3.v1_std, label = "std")
    axislegend()
    fig
end


### calculate `count/nrow` and `mean` of `v2` binned according to `y` and `x`
```julia
df4 = binstats(df, [:y, :x], [0:.2:20, 0:.2:20], [:v2]; missing_bins = true)
```

plotting block
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.y, df.x, color = df.v2, colormap = :thermal, markersize = 1)
    xlims!(0, 20); ylims!(0, 20)
    Axis(fig[1, 2], title = "binned data")
    heatmap!(fig[1, 2], unique(bincenter.(df4[:,1])),unique(bincenter.(df4[:,2])), 
        reshape(df4.v2_mean,length(unique(df4[:,2])),length(unique(df4[:,1]))), 
        colormap = :thermal)
    fig
end

### calculate `median` of `v2` binned according to `y` and `x` using non-uniform `axis_edges`
```julia
df5 = binstats(df, [:y, :x], [(0:0.5:4.5).^2, (0:0.5:4.5).^2], [:v2], grp_function = [], col_function = [median], missing_bins = true)
```

plotting block
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.y, df.x, color = df.v2, colormap = :thermal, markersize = 1)
    xlims!(0, 20); ylims!(0, 20)
    Axis(fig[1, 2], title = "binned data")
    heatmap!(fig[1, 2], unique(bincenter.(df5[:,1])),unique(bincenter.(df5[:,2])), reshape(df5.v2_mean,length(unique(df5[:,2])),length(unique(df5[:,1]))), colormap = :thermal)
    fig
end
