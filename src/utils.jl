getvectortype(::Vector{T}) where T = T

getnodekeys(dmg::Dict) = _getelementkeys([Pair(k,v) for vpg in getfield.(values(dmg), :vprops) for (k,v) in vpg])
getnodekeys(mg::AbstractMetaGraph) = _getelementkeys([Pair(k,v) for (k,v) in mg.vprops]) 

getedgekeys(dmg::Dict) = _getelementkeys([Pair(k,v) for vpg in getfield.(values(dmg), :eprops) for (k,v) in vpg])
getedgekeys(mg::AbstractMetaGraph) = _getelementkeys([Pair(k,v) for (k,v) in mg.eprops])

function _getelementkeys(dprops)
    pairs = [Pair(x,y) for d in getfield.(dprops, :second) for (x,y) in d]
    nodefieldset = Set(getfield.(pairs, :first))
    nodefieldsettypes = [getvectortype([p.second for p in pairs if p.first == nfs]) for nfs in nodefieldset]
    return nodefieldset, nodefieldsettypes
end

function getcompatiblesupertype(elementtype)
    if elementtype <: Bool
        return Bool
    elseif elementtype <: Integer
        return Integer
    elseif elementtype <: Real
        return Real
    else
        return AbstractString
    end
end

savemetagraphkeys(mg::Dict{String, T}, xroot) where T <: NestedGraph = savemetagraphkeys(Dict(k=>v.flatgr for (k,v) in mg) ,xroot)
function savemetagraphkeys(mg::Dict{String, T}, xroot) where T <: AbstractMetaGraph
    for (ndf,nt) in zip(getnodekeys(mg)...)
        xk = addelement!(xroot, "key")
        xk["attr.name"] = string(ndf)
        xk["attr.type"] = graphMLAttributesType_rev[getcompatiblesupertype(nt)]
        xk["for"] = "node"
        xk["id"] = string(ndf)
    end
    for (ndf,nt) in zip(getedgekeys(mg)...)
        xk = addelement!(xroot, "key")
        xk["attr.name"] = string(ndf)
        xk["attr.type"] = graphMLAttributesType_rev[getcompatiblesupertype(nt)]
        xk["for"] = "node"
        xk["id"] = string(ndf)
    end
end

function startgraphmlroot(xdoc)
    xroot = setroot!(xdoc, ElementNode("graphml"))
    xroot["xmlns"] = "http://graphml.graphdrawing.org/xmlns"
    xroot["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    xroot["xsi:schemaLocation"] = "http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"
    return xroot
end

function addallvertswithid(ig, xg)
    for v in vertices(ig)
        xv = addelement!(xg, "node")
        xv["id"] = get_prop(ig, v, :id)
        for (k,v) in props(ig, v)
            k == :id && continue
            xel = addelement!(xv, "data", string(v))
            xel["key"] = k
        end
    end
end
function addalledgeswithid(ig, xg)
    for e in edges(ig)
        xe = addelement!(xg, "edge")
        xe["id"] = get_prop(ig, e, :id)
        xe["source"] = get_prop(ig, src(e), :id)
        xe["target"] = get_prop(ig, dst(e), :id)
        for (k,v) in props(ig, e)
            k == :id && continue
            xel = addelement!(xe, "data", string(v))
            xel["key"] = k
        end
    end
end
