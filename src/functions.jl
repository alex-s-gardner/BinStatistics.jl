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
- `missing_bin = false`: include missing bins

# Examples

```jldoctest
julia> df = DataFrame(x=sin.(0:0.01:100), y = cos.(0:0.01:100), v1 = 0:0.01:100, v2 = (0:0.01:100).^2)

# bin as a function of `x` and return the `nrow` and `mean` of `v1` within each bin. `x` labels are bin centers
julia> binstats(df, :x, [-1, -.5, -0.25, 1], :v1)
3×3 DataFrame
 Row │ x        nrow   v1_mean 
     │ Float64  Int64  Float64 
─────┼─────────────────────────
   1 │  -0.75    3350  51.8438
   2 │  -0.375    841  50.2257
   3 │   0.375   5810  48.9042

# bin as a function of `x` and `y` nd return the `nrow` and `mean` of `v1` within each bin
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1])
6×4 DataFrame
 Row │ x        y        nrow   v1_mean 
     │ Float64  Float64  Int64  Float64 
─────┼──────────────────────────────────
   1 │  -0.75      -0.5   1676  51.3281
   2 │  -0.75       0.5   1674  52.36
   3 │  -0.375     -0.5    434  50.7117
   4 │  -0.375      0.5    407  49.7075
   5 │   0.375     -0.5   2918  49.6149
   6 │   0.375      0.5   2891  48.2039

# bin as a function of `x` and `y` and return the `mean` of `v1` and the `std` of `v2` within each bin
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], grp_function = [], col_function = [mean, std])
6×4 DataFrame
 Row │ x        y        v1_mean  v2_std  
     │ Float64  Float64  Float64  Float64 
─────┼────────────────────────────────────
   1 │  -0.75      -0.5  51.3281  3067.6
   2 │  -0.75       0.5  52.36    3123.3
   3 │  -0.375     -0.5  50.7117  3025.52
   4 │  -0.375      0.5  49.7075  2790.1
   5 │   0.375     -0.5  49.6149  2970.39
   6 │   0.375      0.5  48.2039  2864.74

# bin as a function of `x` and `y` and return the `mean` and `std` of both `v1` and `v2` within each bin
# NOTE: `col_function` from changed `Vector` to `Matrix`, i.e. comma removed from col_function
julia> binstats(df, [:x, :y], [[-1, -.5, -0.25, 1], [-1, 0, 1]], [:v1, :v2], grp_function = [], col_function = [mean std])
6×6 DataFrame
 Row │ x        y        v1_mean  v2_mean  v1_std   v2_std  
     │ Float64  Float64  Float64  Float64  Float64  Float64 
─────┼──────────────────────────────────────────────────────
   1 │  -0.75      -0.5  51.3281  3474.45  28.9892  3067.6
   2 │  -0.75       0.5  52.36    3579.9   28.9626  3123.3
   3 │  -0.375     -0.5  50.7117  3407.85  28.9501  3025.52
   4 │  -0.375      0.5  49.7075  3210.43  27.2289  2790.1
   5 │   0.375     -0.5  49.6149  3300.65  28.9707  2970.39
   6 │   0.375      0.5  48.2039  3149.59  28.7447  2864.74
"""
function  binstats(
    df::DataFrame,
    axis_col::Union{Vector{Symbol}, Vector{String}, Symbol, String},
    axis_edges::AbstractVector, 
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

    # number of axes along which to perfom binning of variables
    naxis = length(axis_col)

    # subset dataframe
    idxcols = DataFrames.index(df)[axis_col]
    if length(idxcols) !== naxis
        error("data frame does not contian fields $axis_col, check kwarg axis_col")
    end
    
    idxcols = vcat(idxcols, DataFrames.index(df)[bin_col])

    # bin data using CatagoricalArrays
    sdf = select(df, idxcols, copycols=false)
    
    fmt(from, to, i; leftclosed, rightclosed) = (from + to)*.5

    for i in 1:naxis
        try
            sdf[!,i] = cut(
            sdf[!,i], 
            axis_edges[i]; 
            extend = missing, 
            labels = fmt);
        catch
            error("axis_edges must be numberic")
        end
    end
    
    if missing_bins
        levels = Vector{Vector{}}(undef, naxis)
        for i in 1:naxis
            levels[i] =  sdf[!,i].pool.levels
        end
    end

    # group data that falls within the same bin
    gdf = groupby(sdf, 1:naxis);

    # drop all data that falls outside of bin edges
    for i = 1:naxis
        gdf = filter(x -> !any(ismissing(x[1,i])), gdf)
    end

    # compute statistics on binned data
    sdf = combine(gdf, (grp_function)..., (naxis+1):length(idxcols) .=> col_function)

    # unwrap CatagoricalArray
    sdf[!,1:naxis] = unwrap.(sdf[!,1:naxis])

    if missing_bins
        sdf = _add_missing_bins(sdf, levels, naxis)
    end

    return sdf
end


"""
Internal function for adding bins that do not contain data
"""
function _add_missing_bins(sdf, levels, naxis)
    # find missing binds
    bins = Iterators.product(levels...)
    bins = setdiff(bins, tuple.(eachcol(sdf[:,1:naxis])...))

    if !isempty(bins)
        # collect tuples into matrix
        bins = reduce(hcat, collect.(bins))
        bins = permutedims(bins,[2,1]);
        #bins = reverse(bins,dims=2)

        # populate missing bins
        mdf = similar(sdf,size(bins,1))
        mdf[!,1:naxis] = bins

        allowmissing!(mdf,(naxis+1):ncol(sdf))
        mdf[!,(naxis+1):end] .= missing

        # append
        allowmissing!(sdf, (naxis+1):ncol(sdf))
        append!(sdf,mdf)

        # sort
        sdf = sort!(sdf, 1:naxis)
    end

    return sdf
end
