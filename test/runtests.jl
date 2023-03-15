using IRViz
using InteractiveUtils
using ImageIO: ImageIO  # Need to load this to avoid LazyModule's world-age issues
using XTermColors: XTermColors  # Needed to load this to avoid LazyModule's world-age issues
using ReferenceTests
using Test


for file in ("code-flow-graph.jl",)
    @testset "$file" begin
        include(file)
    end
end