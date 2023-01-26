# BinStatistics.jl
Highly flexible and efficient computation of n-dimensional binned statistic(s) for n-variable(s)

BinStatistics provides the `binstats` function that is build on top of DataFrames.jl 
and CatagoricalArrays.jl

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

### Example 1: calculate count/nrow and mean of v1 binned according to x
```julia
df1 = binstats(df, :x, 0:0.1:20, :v1)

200×3 DataFrame
 Row │ x             nrow   v1_mean  
     │ String        Int64  Float64  
─────┼───────────────────────────────
   1 │ [0.0, 0.1)     5081  0.973442
   2 │ [0.1, 0.2)     5079  1.03621
  ⋮  │      ⋮          ⋮       ⋮
 199 │ [19.8, 19.9)   5201  0.521451
 200 │ [19.9, 20.0)   5050  0.490683
```
![binstats example 1](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/1.png?raw=true)


### Example 2: calculate count/nrow and mean of v1 and v2 binned according to x
```julia
df2 = binstats(df, :x, 0:0.1:20, ["v1", "v2"])

200×4 DataFrame
 Row │ x             nrow   v1_mean   v2_mean   
     │ String        Int64  Float64   Float64   
─────┼──────────────────────────────────────────
   1 │ [0.0, 0.1)     5081  0.973442  0.0567808
   2 │ [0.1, 0.2)     5079  1.03621   0.0653569
  ⋮  │      ⋮          ⋮       ⋮          ⋮
 199 │ [19.8, 19.9)   5201  0.521451  0.0459481
 200 │ [19.9, 20.0)   5050  0.490683  0.0915996
```
![binstats example 2](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/2.png?raw=true)


### Example 3: calculate count/nrow, mean, medain and std of v1 binned according to x
```julia
df3 = binstats(df, :x, 0:0.1:20, :v1; col_function = [mean, median, std])

200×5 DataFrame
 Row │ x             nrow   v1_mean   v1_median  v1_std  
     │ String        Int64  Float64   Float64    Float64 
─────┼───────────────────────────────────────────────────
   1 │ [0.0, 0.1)     5081  0.973442   0.973191  2.97307
   2 │ [0.1, 0.2)     5079  1.03621    1.02465   2.99917
  ⋮  │      ⋮          ⋮       ⋮          ⋮         ⋮
 199 │ [19.8, 19.9)   5201  0.521451   0.436727  3.01971
 200 │ [19.9, 20.0)   5050  0.490683   0.482965  3.00587
```
![binstats example 3](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/3.png?raw=true)


### Example 4: calculate count/nrow  and mean of v2 binned according to y and x
```julia
df4 = binstats(df, [:y, :x], [0:.2:20, 0:.2:20], [:v2]; missing_bins = true)

10000×4 DataFrame
   Row │ y             x             nrow   v2_mean 
       │ String        String        Int64  Float64 
───────┼────────────────────────────────────────────
     1 │ [0.0, 0.2)    [0.0, 0.2)      104  1.11192
     2 │ [0.0, 0.2)    [0.2, 0.4)       87  1.40544
   ⋮   │      ⋮             ⋮          ⋮       ⋮
  9999 │ [19.8, 20.0)  [19.6, 19.8)     87  1.8668
 10000 │ [19.8, 20.0)  [19.8, 20.0)    106  2.04332
```
![binstats example 4](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/4.png?raw=true)

### Example 5: calculate median of v2 binned according to y and x using non-uniform axis_edges
```julia
df5 = binstats(df, [:y, :x], [(0:0.5:4.5).^2, (0:0.5:4.5).^2], [:v2], grp_function = [], col_function = [median], missing_bins = true)

81×3 DataFrame
 Row │ y              x              v2_median   
     │ String         String         Float64     
─────┼───────────────────────────────────────────
   1 │ [0.0, 0.25)    [0.0, 0.25)     0.940375
   2 │ [0.0, 0.25)    [0.25, 1.0)     1.76134
  ⋮  │       ⋮              ⋮             ⋮
  80 │ [16.0, 20.25)  [12.25, 16.0)  -0.0137548
  81 │ [16.0, 20.25)  [16.0, 20.25)  -0.00810516
```
![binstats example 5](https://github.com/alex-s-gardner/BinStatistics.jl/blob/main/assets/images/5.png?raw=true)



## Plotting script
```julia
# Example 1
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.x, df.v1)
    Axis(fig[1, 2], title = "binned data")
    scatter!(fig[1, 2], bincenter.(df1[:,1]), df1.v1_mean)  
    fig
end

# Example 2
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

# Example 3
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

# Example 4
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

# Example 5
begin 
    fig = Figure()
    Axis(fig[1, 1], title = "raw data")
    scatter!(fig[1, 1], df.y, df.x, color = df.v2, colormap = :thermal, markersize = 1)
    xlims!(0, 20); ylims!(0, 20)
    Axis(fig[1, 2], title = "binned data")
    heatmap!(fig[1, 2], unique(bincenter.(df5[:,1])),unique(bincenter.(df5[:,2])),
        reshape(df5.v2_mean,length(unique(df5[:,2])),length(unique(df5[:,1]))), colormap = :thermal)
    fig
end
```
