module BinStatistics
    using DataFrames
    using CategoricalArrays
    using Statistics

    export binstats
    export binedges
    export bincenter
    include("functions.jl")
end
