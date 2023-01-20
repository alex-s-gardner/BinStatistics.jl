"""
    binstats(df, binv_names, i_edges, j_edges, v_names; 
        grp_functions = [nrow], col_functions= [mean])
    
Returns a DataFrame containing function values for binned variables of `df`.

# Arguments
- `binvar_names`: names of binning axes variables
- `binvar_edges`: bin edges for binning axes variables `binv_names`
- `var_names`: name(s) of variables to be binned
- `grp_functions`: column independent funcitons to be applied at group level
- `var_functions`: column dependent funcitons to be applied to `var_names` at group level

# Examples

```jldoctest
julia> df = DataFrame(x=sin.(0:0.01:100), y = cos.(0:0.01:100), v1 = 0:0.01:100, v2 = (0:0.01:100).^2)

# return default `nrow` and `mean` of variable `v1` when binned as a function of `x`
julia> binstats(df, [:x], [[-1, -.5, -0.25, 1]], [:v1])
3×3 DataFrame
Row │ x              nrow   v1_mean 
    │ Cat…?          Int64  Float64 
─────┼───────────────────────────────
1 │ [-1.0, -0.5)    3350  51.8438
2 │ [-0.5, -0.25)    841  50.2257
3 │ [-0.25, 1.0)    5810  48.9042

# bin as a function of `x` and `y`
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1])
7×4 DataFrame
Row │ x              y            nrow   v1_mean 
    │ Cat…?          Cat…?        Int64  Float64 
─────┼────────────────────────────────────────────
1 │ [-1.0, -0.5)   [-1.0, 0.0)   1676  51.3281
2 │ [-1.0, -0.5)   [0.0, 1.0)    1674  52.36
⋮  │       ⋮             ⋮         ⋮       ⋮
7 │ [-0.25, 1.0)   [0.0, 1.0)    2891  48.2039

# bin as a function of `x` and `y` and return the `meadian` of `v1` and the `std` of `v2` 
# within each bin
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], grp_functions = [], col_functions = [mean, std])
7×4 DataFrame
Row │ x              y            v1_mean  v2_std  
    │ Cat…?          Cat…?        Float64  Float64 
─────┼──────────────────────────────────────────────
    1 │ [-1.0, -0.5)   [-1.0, 0.0)  51.3281  3067.6
    2 │ [-1.0, -0.5)   [0.0, 1.0)   52.36    3123.3
    ⋮  │       ⋮             ⋮          ⋮        ⋮
    7 │ [-0.25, 1.0)   [0.0, 1.0)   48.2039  2864.74

# bin as a function of `x` and `y` and return the `meadian` abd `std` for both `v1` 
# and `v2` within each bin... NOTE: `col_functions`` from changed `Vector` to `Matrix` 
# i.e. comma removed
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], grp_functions = [], col_functions = [mean std])

7×6 DataFrame
Row │ x              y            v1_mean  v2_mean  v1_std    v2_std  
    │ Cat…?          Cat…?        Float64  Float64  Float64   Float64 
─────┼─────────────────────────────────────────────────────────────────
    1 │ [-1.0, -0.5)   [-1.0, 0.0)  51.3281  3474.45   28.9892  3067.6
    2 │ [-1.0, -0.5)   [0.0, 1.0)   52.36    3579.9    28.9626  3123.3
    ⋮  │       ⋮             ⋮          ⋮        ⋮        ⋮         ⋮
    7 │ [-0.25, 1.0)   [0.0, 1.0)   48.2039  3149.59   28.7447  2864.74
"""
function  binstats(
    df::DataFrame,
    binv_names::Union{Vector{Symbol}, Vector{String}},
    binv_edges::AbstractVector, #Union{Vector{Vector{<:Real}},Vector{Vector{StepRange{}}}},
    v_names::Union{Vector{Symbol}, Vector{String}};
    grp_functions::F1 = [nrow],
    col_functions::F2 = [mean]
) where {F1>:AbstractVector{Function}, F2>:AbstractVector{Function}}

    nbinv = length(binv_names)
    nv = length(v_names)

    idxcols = DataFrames.index(df)[binv_names]
    if length(idxcols) !== nbinv
        error("data frame does not contian fields $binv_names, check kwarg binv_names")
    end

    idxcols = vcat(idxcols, DataFrames.index(df)[v_names])
    #if length(idxcols) < 3 
    #    error("data frame does not contian fields $v_names, check kwarg v_names")
    #end

    sdf = select(df, idxcols, copycols=false)
    for i in eachindex(binv_names)
        sdf[!,i] = cut(sdf[!,i], binv_edges[i], extend=missing);
    end

    sdf = combine(groupby(sdf, 1:nbinv), (grp_functions)..., (nbinv+1):(ncol(sdf)) .=> col_functions)
    return sdf
end