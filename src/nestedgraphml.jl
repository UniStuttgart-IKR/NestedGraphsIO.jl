function instantiate_nestedgraph(flatgraphtype::Type, graphnode, ns)
    nocompgraphs = length(findall("x:node/x:graph/x:node/x:graph", graphnode, ["x"=>ns]))
    secondtype = nocompgraphs == 0 ? flatgraphtype : Union{NestedGraph, flatgraphtype}
    NestedGraph{Int, flatgraphtype, secondtype}(;extrasubgraph=true)
end


function _load_nestedgraph_fromnode(graphnode::EzXML.Node, keyprops::Dict{String, AttrKey}, ns, flatgraphtype::Type{T}) where {T <: AbstractGraph}

    if length(findall("x:node[./x:graph]", graphnode, ["x"=>ns])) == 0
        return _loadmetagraph_fromnode(graphnode, keyprops)
    end

    mycompgr = instantiate_nestedgraph(flatgraphtype, graphnode,ns)
    set_prop!(mycompgr, :id, graphnode["id"])
    set_indexing_prop!(mycompgr, :id)

    for (i,node) in enumerate(findall("x:node", graphnode, ["x"=>ns]))
        if any(nodename.(elements(node)) .== "graph")
            grtemp =  _load_nestedgraph_fromnode(findfirst("x:graph", node, ["x"=>ns]), keyprops, ns, flatgraphtype)
            add_vertex!(mycompgr, grtemp)
        else
            addmetagraphmlnode!(mycompgr, node, nodedefaults(keyprops), keyprops, ns)
        end
    end

    # only top layer edges (inner edges will be considered recursively)
    for edge in findall("x:edge", graphnode, ["x"=>ns])
        addmetagraphmledge!(mycompgr, edge, edgedefaults(keyprops), keyprops, ns)
    end
    return mycompgr
end

function loadnestedgraphml(io::IO, gname::String)
    doc = readxml(io)
    ns = namespace(doc.root)
    keyprops = _get_key_props(doc)

    # get only top layer graphs
    for graphnode in findall("x:graph", doc.root, ["x"=>ns])
        if graphnode["id"] == gname
            return _load_nestedgraph_fromnode(graphnode, keyprops, ns, metagraphtype(graphnode))
        end
    end
end
function loadnestedgraphml(io::IO)
    doc = readxml(io)
    ns = namespace(doc.root)
    keyprops = _get_key_props(doc)
    graphnode = findfirst("x:graph", doc.root, ["x"=>ns])
    return _load_nestedgraph_fromnode(graphnode, keyprops, ns, metagraphtype(graphnode))
end

function rec_savenestedgraph(mg::AbstractMetaGraph, xg)
    addallvertswithid(mg, xg)
    addalledgeswithid(mg, xg)
end

function rec_savenestedgraph(ng::NestedGraph, xg)
    for ig in ng.grv
        if has_prop(ig, :id)
            xv = addelement!(xg, "node")
            xv["id"] = get_prop(ig, :id)
            xgv = addelement!(xv, "graph")
            xgv["id"] = get_prop(ig, :id)
            xgv["edgedefault"] = is_directed(ig) ? "directed" : "undirected"
            # recursive function for the inner graph
            rec_savenestedgraph(ig, xgv)
        else
            addallvertswithid(ig, xg)
            addalledgeswithid(ig, xg)
            for e in ng.neds
                xe = addelement!(xg, "edge")
                srcnd = NestedGraphs.vertex(ng, src(e))
                dstnd = NestedGraphs.vertex(ng, dst(e))
                xe["id"] = get_prop(ng.flatgr, srcnd, dstnd, :id)
                xe["source"] = get_prop(ng.flatgr, srcnd, :id)
                xe["target"] = get_prop(ng.flatgr, dstnd, :id)
                for (k,v) in props(ng, srcnd, dstnd)
                    k == :id && continue
                    xel = addelement!(xe, "data", string(v))
                    xel["key"] = k
                end
            end
        end
    end
end

function savenestedgraphml_mult(io::IO, dng::Dict{String,T}) where T<:NestedGraph
    xdoc = XMLDocument()
    xroot = startgraphmlroot(xdoc)
    savemetagraphkeys(dng, xroot)

    for (gname, mg) in dng
        xg = addelement!(xroot, "graph")
        xg["id"] = gname
        xg["edgedefault"] = is_directed(mg) ? "directed" : "undirected"
        rec_savenestedgraph(mg, xg)
    end

    prettyprint(io, xdoc)
    return nothing
end

"""
$(TYPEDSIGNATURES) 
"""
loadgraph(io::IO, ::GraphMLFormat, ::NestedGraphFormat) = loadnestedgraphml(io)
"""
$(TYPEDSIGNATURES) 
"""
loadgraph(io::IO, gname::String, ::GraphMLFormat, ::NestedGraphFormat) = loadnestedgraphml(io, gname)

"""
$(TYPEDSIGNATURES) 
"""
savegraph(io::IO, g::NestedGraph, gname::String, ::GraphMLFormat) = savenestedgraphml_mult(io, Dict(gname=>g))
