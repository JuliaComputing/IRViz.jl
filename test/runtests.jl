using IRViz
using InteractiveUtils
using ReferenceTests
using Test


for file in ("code-flow-graph.jl",)
    @testset "$file" begin
        include(file)
    end
end