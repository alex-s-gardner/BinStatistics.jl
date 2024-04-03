# BinStatistics.jl

Highly flexible and efficient computation of n-dimensional binned statistic(s) for n-variable(s)

BinStatistics provides the `binstats` function that is build on top of DataFrames.jl 
and CatagoricalArrays.jl

`binstats` is 2X-10X faster than Python's scipy-1.8.0

## binstats function
```julia
"""
    binstats(df, axis_col, axis_edges, bin_col; 
        grp_function = [nrow], col_function = [mean], missing_bin = false)
    
Returns a DataFrame containing function values for binned variables of `df`.

# Arguments
- `axis_col`: binning axes column(s)
- `axis_edges`: bin edges for `axis_col`
- `bin_col`: column variable(s) to be binned
- `grp_function = [nrow]`: column independent funciton(s) to be applied at group level
- `var_function = [mean]`: column dependent funciton(s) to be applied to `bin_col` at group level
- `missing_bins = false`: include missing bins
"""
```

## Examples

### load packages
```julia
using Pkg
Pkg.add("BinStatistics")
Pkg.add("DataFrames")
Pkg.add("Statistics")
Pkg.add("CairoMakie")
using BinStatistics
using DataFrames
using Statistics
using CairoMakie
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

### Example 1: calculate count/nrow and mean of v1 binned according to x
```julia
df1 = binstats(df, :x, 0:0.1:20, :v1)

200×3 DataFrame
 Row │ x        nrow   v1_mean  
     │ Float64  Int64  Float64  
─────┼──────────────────────────
   1 │    0.05   4932  0.957416
   2 │    0.15   4922  0.966772
  ⋮  │    ⋮       ⋮       ⋮
 199 │   19.85   5085  0.56495
 200 │   19.95   4958  0.491761

 NOTE: `x` labels are bin centers
```
![binstats example 1](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/1.png?raw=true)


### Example 2: calculate count/nrow and mean of v1 and v2 binned according to x
```julia
df2 = binstats(df, :x, 0:0.1:20, ["v1", "v2"])

200×4 DataFrame
 Row │ x        nrow   v1_mean   v2_mean   
     │ Float64  Int64  Float64   Float64   
─────┼─────────────────────────────────────
   1 │    0.05   4932  0.957416  0.0521698
   2 │    0.15   4922  0.966772  0.134747
  ⋮  │    ⋮       ⋮       ⋮          ⋮
 199 │   19.85   5085  0.56495   0.0731969
 200 │   19.95   4958  0.491761  0.113065
```
![binstats example 2](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/2.png?raw=true)


### Example 3: calculate count/nrow, mean, medain and std of v1 binned according to x
```julia
df3 = binstats(df, :x, 0:0.1:20, :v1; col_function = [mean, median, std])

200×5 DataFrame
 Row │ x        nrow   v1_mean   v1_median  v1_std  
     │ Float64  Int64  Float64   Float64    Float64 
─────┼──────────────────────────────────────────────
   1 │    0.05   4932  0.957416   1.01216   2.94134
   2 │    0.15   4922  0.966772   0.990715  2.95307
  ⋮  │    ⋮       ⋮       ⋮          ⋮         ⋮
 199 │   19.85   5085  0.56495    0.617968  3.00214
 200 │   19.95   4958  0.491761   0.487893  2.9561
```
![binstats example 3](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/3.png?raw=true)


### Example 4: calculate count/nrow  and mean of v2 binned according to y and x
```julia
df4 = binstats(df, [:y, :x], [0:.2:20, 0:.2:20], [:v2]; missing_bins = true)

10000×4 DataFrame
   Row │ y        x        nrow   v2_mean 
       │ Float64  Float64  Int64  Float64 
───────┼──────────────────────────────────
     1 │     0.1      0.1    102  1.0629
     2 │     0.1      0.3     87  1.46221
   ⋮   │    ⋮        ⋮       ⋮       ⋮
  9999 │    19.9     19.7     96  1.80224
 10000 │    19.9     19.9     94  2.40527
```
![binstats example 4](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/4.png?raw=true)

### Example 5: calculate median of v2 binned according to y and x using non-uniform axis_edges
```julia
df5 = binstats(df, [:y, :x], [(0:0.5:4.5).^2, (0:0.5:4.5).^2], [:v2], grp_function = [], col_function = [median], missing_bins = true)

81×3 DataFrame
 Row │ y        x        v2_median   
     │ Float64  Float64  Float64     
─────┼───────────────────────────────
   1 │   0.125    0.125   0.94437
   2 │   0.125    0.625   1.79481
  ⋮  │    ⋮        ⋮          ⋮
  80 │  18.125   14.125  -0.00643648
  81 │  18.125   18.125   0.00196411
```
![binstats example 5](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/5.png?raw=true)

### Example 6: apply custom function to v2, binned according to y and x
```julia
# create a median absolute deviation function
function mad(x)
    median(abs.(x .- median(x))) 
end
# binstats also accepts anonymous functions but the output will be assinged a generic name

# apply to grouped data
df6 = binstats(df, [:y, :x], [0:1:20, 0:1:20], [:v2], grp_function = [], col_function = [mad],; missing_bins = true)

400×3 DataFrame
 Row │ y        x        v2_mad  
     │ Float64  Float64  Float64 
─────┼───────────────────────────
   1 │     0.5      0.5  2.04322
   2 │     0.5      1.5  2.08714
  ⋮  │    ⋮        ⋮        ⋮
 399 │    19.5     18.5  2.17078
 400 │    19.5     19.5  2.02198
```
![binstats example 6](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/6.png?raw=true)

## Plotting script
```julia
# Example 1
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], df1[:,1], df1.v1_mean)  
    fig
end

# Example 2
begin
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    scatter!(fig[1, 1], df.x, df.v2)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], df2[:,1], df2.v1_mean, label = "v1")
    scatter!(fig[1, 2], df2[:,1], df2.v2_mean, label = "v2")
    axislegend()
    fig
end

# Example 3
begin
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], df3[:,1], df3.v1_mean, label = "mean")
    scatter!(fig[1, 2], df3[:,1], df3.v1_median, label = "median")
    scatter!(fig[1, 2], df3[:,1], df3.v1_std, label = "std")
    axislegend()
    fig
end

# Example 4
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.y, df.x, color = df.v2, colormap = :thermal, markersize = 1)
    xlims!(0, 20); ylims!(0, 20)
    Axis(fig[1, 2], title = "binned data")
    heatmap!(fig[1, 2], unique(df4[:,1]),unique(df4[:,2]), 
        reshape(df4.v2_mean,length(unique(df4[:,2])),length(unique(df4[:,1]))), 
        colormap = :thermal)
    fig
end

# Example 5
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.y, df.x, color = df.v2, colormap = :thermal, markersize = 1)
    xlims!(0, 20); ylims!(0, 20)
    Axis(fig[1, 2], title = "binned data")
    heatmap!(fig[1, 2], unique(df5[:,1]),unique(df5[:,2]),
        reshape(df5.v2_median,length(unique(df5[:,2])),length(unique(df5[:,1]))), colormap = :thermal)
    fig
end

# Example 6
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.y, df.x, color = df.v2, colormap = :thermal, markersize = 1)
    xlims!(0, 20); ylims!(0, 20)
    Axis(fig[1, 2], title = "binned data")
    heatmap!(fig[1, 2], unique(df6[:,1]),unique(df6[:,2]), 
        reshape(df6.v2_mad,length(unique(df6[:,2])),length(unique(df6[:,1]))), 
        colormap = :thermal)
    fig
end

```


# Similar packages
## Julia
[BinnedStatistics.jl](https://github.com/kirklong/BinnedStatistics.jl) for single variable 1-D binned statistics

## Python
Scipy's [binned_statistic](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binned_statistic.html), [binned_statistic_2d](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binned_statistic_2d.html), and [binned_statistic_dd](scipy.stats.binned_statistic_dd) for single variable 1-, 2-, and n-dimensional binned statistics
