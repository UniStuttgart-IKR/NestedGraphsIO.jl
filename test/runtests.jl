using Graphs, NestedGraphs
using NestedGraphsIO
using MetaGraphs
using Test, TestSetExtensions


import GraphIO.GraphML: GraphMLFormat
import NestedGraphs: NestedGraphFormat
import Graphs: AbstractGraph, loadgraph, loadgraphs, savegraph
import MetaGraphs: AbstractMetaGraph, MGFormat

testdir = dirname(@__FILE__)

include("testutils.jl")

@testset "NestedGraphsIO.jl" begin
    @includetests ["metagraphsio", "nestedgraphsio"]
end
