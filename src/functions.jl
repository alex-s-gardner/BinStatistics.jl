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

# Examples

```jldoctest
julia> df = DataFrame(x=sin.(0:0.01:100), y = cos.(0:0.01:100), v1 = 0:0.01:100, v2 = (0:0.01:100).^2)

# return default `nrow` and `mean` of variable `v1` when binned as a function of `x`
julia> binstats(df, [:x], [[-1, -.5, -0.25, 1]], [:v1])
3×3 DataFrame
 Row │ x              nrow   v1_mean 
     │ String         Int64  Float64 
─────┼───────────────────────────────
   1 │ [-1.0, -0.5)    3350  51.8438
   2 │ [-0.5, -0.25)    841  50.2257
   3 │ [-0.25, 1.0)    5810  48.9042

# bin as a function of `x` and `y`
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1])
6×4 DataFrame
 Row │ x              y            nrow   v1_mean 
     │ String         String       Int64  Float64 
─────┼────────────────────────────────────────────
   1 │ [-1.0, -0.5)   [-1.0, 0.0)   1676  51.3281
   2 │ [-1.0, -0.5)   [0.0, 1.0)    1674  52.36
   3 │ [-0.5, -0.25)  [-1.0, 0.0)    434  50.7117
   4 │ [-0.5, -0.25)  [0.0, 1.0)     407  49.7075
   5 │ [-0.25, 1.0)   [-1.0, 0.0)   2918  49.6149
   6 │ [-0.25, 1.0)   [0.0, 1.0)    2891  48.2039

# bin as a function of `x` and `y` and return the `meadian` of `v1` and the `std` of `v2` 
# within each bin
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], grp_function = [], col_function = [mean, std])
6×4 DataFrame
 Row │ x              y            v1_mean  v2_std  
     │ String         String       Float64  Float64 
─────┼──────────────────────────────────────────────
   1 │ [-1.0, -0.5)   [-1.0, 0.0)  51.3281  3067.6
   2 │ [-1.0, -0.5)   [0.0, 1.0)   52.36    3123.3
   3 │ [-0.5, -0.25)  [-1.0, 0.0)  50.7117  3025.52
   4 │ [-0.5, -0.25)  [0.0, 1.0)   49.7075  2790.1
   5 │ [-0.25, 1.0)   [-1.0, 0.0)  49.6149  2970.39
   6 │ [-0.25, 1.0)   [0.0, 1.0)   48.2039  2864.74

# bin as a function of `x` and `y` and return the `meadian` abd `std` for both `v1` 
# and `v2` within each bin... NOTE: `col_functions`` from changed `Vector` to `Matrix` 
# i.e. comma removed
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], grp_function = [], col_function = [mean std])

6×6 DataFrame
 Row │ x              y            v1_mean  v2_mean  v1_std   v2_std  
     │ String         String       Float64  Float64  Float64  Float64 
─────┼────────────────────────────────────────────────────────────────
   1 │ [-1.0, -0.5)   [-1.0, 0.0)  51.3281  3474.45  28.9892  3067.6
   2 │ [-1.0, -0.5)   [0.0, 1.0)   52.36    3579.9   28.9626  3123.3
   3 │ [-0.5, -0.25)  [-1.0, 0.0)  50.7117  3407.85  28.9501  3025.52
   4 │ [-0.5, -0.25)  [0.0, 1.0)   49.7075  3210.43  27.2289  2790.1
   5 │ [-0.25, 1.0)   [-1.0, 0.0)  49.6149  3300.65  28.9707  2970.39
   6 │ [-0.25, 1.0)   [0.0, 1.0)   48.2039  3149.59  28.7447  2864.74
"""
function  binstats(
    df::DataFrame,
    axis_col::Union{Vector{Symbol}, Vector{String}, Symbol, String},
    axis_edges::AbstractVector, #Union{Vector{Vector{<:Real}},Vector{Vector{StepRange{}}}},
    bin_col::Union{Vector{Symbol}, Vector{String}, Symbol, String};
    grp_function::F1 = [nrow],
    col_function::F2 = [mean],
    missing_bins::Bool = false
) where {F1>:Union{AbstractVector{Function}, Function}, 
        F2>:Union{AbstractVector{Function}, Function}}

    # allow for vector or element inputs
    axis_col isa AbstractVector || (axis_col = [axis_col])
    axis_edges isa AbstractArray{<:AbstractArray} || (axis_edges = [axis_edges])
    bin_col isa AbstractVector || (bin_col = [bin_col])
    grp_function isa AbstractArray || (grp_function = [grp_function])
    col_function isa AbstractArray || (col_function = [col_function])

    # number of axes for binning
    nbinv = length(axis_col)

    # subset dataframe
    idxcols = DataFrames.index(df)[axis_col]
    if length(idxcols) !== nbinv
        error("data frame does not contian fields $axis_col, check kwarg axis_col")
    end
    
    idxcols = vcat(idxcols, DataFrames.index(df)[bin_col])

    # bin data using CatagoricalArrays
    sdf = select(df, idxcols, copycols=false)
    for i in eachindex(axis_col)
        println(axis_edges[i])
        sdf[!,i] = cut(sdf[!,i], axis_edges[i], extend=missing);
    end
    
    if missing_bins
        levels = Vector{Vector{String}}(undef, nbinv)
        for i in 1:nbinv
            levels[i] =  sdf[!,i].pool.levels
        end
    end

    # group data that falls within the same bin
    gdf = groupby(sdf, 1:nbinv);
    


    # drop all data that falls outside of bin edges
    for i = 1:nbinv
        gdf = filter(x -> !any(ismissing(x[1,i])), gdf)
    end

    # compute statistics on binned data
    sdf = combine(gdf, (grp_function)..., (nbinv+1):length(idxcols) .=> col_function)

    # unwrap CatagoricalArray
    sdf[!,1:nbinv] = unwrap.(sdf[!,1:nbinv])

    if missing_bins
        # find missing binds
        bins = Iterators.product(levels...)
        bins = setdiff(bins, tuple.(eachcol(sdf[:,1:nbinv])...))

        if !isempty(bins)
            # collect tuples into matrix
            bins = reduce(hcat, collect.(bins))
            bins = permutedims(bins,[2,1]);
            #bins = reverse(bins,dims=2)

            # populate missing bins
            mdf = similar(sdf,size(bins,1))
            mdf[!,1:nbinv] = bins

            allowmissing!(mdf,(nbinv+1):ncol(sdf))
            mdf[!,(nbinv+1):end] .= missing

            # append
            allowmissing!(sdf, (nbinv+1):ncol(sdf))
            append!(sdf,mdf)

            # sort
           
        end
    end

    #sdf = sort!(sdf, nbinv:-1:1)
    return sdf
end


"""
    binedges(ca_edges)
Converts CatagoricalArray bin edge strings to bin edges a vector of Float64s
"""
function binedges(ca_edges::String)
    edges = split(ca_edges, ", ")
    edges = [parse(Float64,edges[1][2:end]), parse(Float64,edges[2][1:end-1])]
    return edges
end


"""
    bincenter(edges)
Converts bin edges to bin center
"""
function bincenter(edges::Vector{<:Real})
    center = sum(edges) /2
    return center
end

"""
    bincenter(binvar_edges)
Converts CatagoricalArray bin edge strings to bin center Float64
"""
function bincenter(ca_edge::String)
    edges = binedges(ca_edge)
    center = sum(edges) /2
    return center
end
