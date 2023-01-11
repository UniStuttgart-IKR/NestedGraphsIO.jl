module NestedGraphsIO

using EzXML
using Graphs, NestedGraphs, MetaGraphs, GraphIO
using DocStringExtensions

import GraphIO.GraphML: GraphMLFormat
import NestedGraphs: NestedGraphFormat
import Graphs: AbstractGraph, loadgraph, loadgraphs, savegraph
import MetaGraphs: AbstractMetaGraph, MGFormat

include("utils.jl")
include("metagraphml.jl")
include("nestedgraphml.jl")

end
