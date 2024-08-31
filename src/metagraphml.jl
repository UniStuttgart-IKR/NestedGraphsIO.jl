@enum GraphlMLAttributesDomain atgraph atnode atedge atall
const graphlMLAttributesDomain = Dict("graph" => atgraph,
                                      "node" => atnode,
                                      "edge" => atedge,
                                      "all" => atall)

@enum GraphlMLAttributesType atboolean atint atlong atfloat atdouble atstring
const graphMLAttributesType = Dict("int" => Int,
                                   "boolean" => Bool,
                                   "long" => Int128,
                                   "float" => Float64,
                                   "double" => Float64,
                                   "string" => String)
const graphMLAttributesType_rev = Dict(Bool => "boolean",
                                   Integer => "long",
                                   Real => "float",
                                   AbstractString => "string")

struct AttrKey{T}
    id::String
    name::String
    domain::GraphlMLAttributesDomain
    type::Type{T}
    default::Union{T,Nothing}
end

instantiatemetagraph(graphnode::EzXML.Node) = graphnode["edgedefault"] == "directed" ? MetaDiGraph() : MetaGraph()
metagraphtype(graphnode::EzXML.Node) = graphnode["edgedefault"] == "directed" ? MetaDiGraph{Int, Float64} : MetaGraph{Int, Float64}

nodedefaults(keyprops::Dict{String, AttrKey}) = Iterators.filter(v -> getfield(v,:default) !== nothing && getfield(v,:domain) == atnode, values(keyprops)) |> collect
edgedefaults(keyprops::Dict{String, AttrKey}) = Iterators.filter(v -> getfield(v,:default) !== nothing && getfield(v,:domain) == atedge, values(keyprops)) |> collect

function addmetagraphmlnode!(gr::AbstractGraph, node::EzXML.Node, defaults::Vector{AttrKey}, keyprops::Dict{String, AttrKey}, ns::String)
    add_vertex!(gr)
    i = length(vertices(gr))
    set_prop!(gr, i, :id, string(node["id"]))
    for def in defaults
        set_prop!(gr, i, Symbol(def.name), def.default)
    end
    for data in findall("x:data", node, ["x"=>ns])
        key = keyprops[data["key"]]
        set_prop!(gr, i, Symbol(key.name), key.type == String || key.name == "id"  ? strip(nodecontent(data)) : parse(key.type, nodecontent(data)))
    end
end

function addmetagraphmledge!(gr::AbstractGraph, edge::EzXML.Node, defaults::Vector{AttrKey}, keyprops::Dict{String, AttrKey}, ns::String)
    srcnode = gr[string(edge["source"]),:id]
    trgnode = gr[string(edge["target"]),:id]
    add_edge!(gr, srcnode, trgnode)
    if haskey(edge, "id")
        set_prop!(gr, srcnode, trgnode, :id, string(edge["id"]))
    end
    for def in defaults
        set_prop!(gr, srcnode, trgnode, Symbol(def.name), def.default)
    end
    for data in findall("x:data", edge, ["x"=>ns])
        set_prop!(gr, srcnode, trgnode, Symbol(keyprops[data["key"]].name), keyprops[data["key"]].type == String ? strip(nodecontent(data)) : parse(keyprops[data["key"]].type, nodecontent(data)))
    end
end

function _get_key_props(doc::EzXML.Document)
    ns = namespace(doc.root)
    keynodes = findall("//x:key", doc.root, ["x"=>ns])
    keyprops = Dict{String,AttrKey}()
    for keynode in keynodes
        if any(x -> nodename(x)=="attr.type",attributes(keynode))
            attrtype = graphMLAttributesType[strip(keynode["attr.type"])]
            keyadded = false
            for childnode in EzXML.eachnode(keynode)
                if EzXML.nodename(childnode) == "default"
                    defaultcontent = strip(nodecontent(childnode))
                    keyprops[keynode["id"]] = AttrKey(keynode["id"], keynode["attr.name"], graphlMLAttributesDomain[keynode["for"]], attrtype, attrtype == String ? defaultcontent : parse(attrtype, defaultcontent) )
                    keyadded = true
                end
            end
            if !keyadded
                keyprops[keynode["id"]] = AttrKey(keynode["id"], keynode["attr.name"], graphlMLAttributesDomain[keynode["for"]], attrtype, nothing )
            end
        end
    end
    return keyprops
end

function _loadmetagraph_fromnode(graphnode::EzXML.Node, keyprops::Dict{String, AttrKey})
    ns = namespace(graphnode)
    gr = instantiatemetagraph(graphnode)
    if haskey(graphnode, "id")
        set_prop!(gr, :id, string(graphnode["id"]))
    end

    for data in findall("x:data", graphnode, ["x"=>ns])
        key = keyprops[data["key"]]
        set_prop!(gr, Symbol(key.name), key.type == String || key.name == "id"  ? strip(nodecontent(data)) : parse(key.type, nodecontent(data)))
    end

    set_indexing_prop!(gr, :id)
    for (i,node) in enumerate(findall("x:node", graphnode, ["x"=>ns]))
        addmetagraphmlnode!(gr, node, nodedefaults(keyprops), keyprops, ns)
    end

    for edge in findall("x:edge", graphnode, ["x"=>ns])
        addmetagraphmledge!(gr, edge, edgedefaults(keyprops), keyprops, ns)
    end
    return gr
end

#TODO carefull if graphml format is nested
function loadmetagraphml(io::IO, gname::String)
    doc = readxml(io)
    ns = namespace(doc.root)
    keyprops = _get_key_props(doc)

    for graphnode in findall("//x:graph", doc.root, ["x"=>ns])
        if graphnode["id"] == gname
            return _loadmetagraph_fromnode(graphnode, keyprops)
        end
    end
end
function loadmetagraphml_mult(io::IO)
    doc = readxml(io)
    ns = namespace(doc.root)
    keyprops = _get_key_props(doc)

    graphnodes = findall("//x:graph", doc.root, ["x"=>ns])

    gcount = 1

    graphs = Dict{String, AbstractMetaGraph}()
    for graphnode in graphnodes
        gkey = haskey(graphnode, "id") ? string(graphnode["id"]) : string("graph", gcount)
        graphs[gkey] = _loadmetagraph_fromnode(graphnode, keyprops)
     end
    return graphs
end

function savemetagraphml_mult(io::IO, dmg::Dict{String,T}) where T <: AbstractMetaGraph
    xdoc = XMLDocument()
    xroot = startgraphmlroot(xdoc)
    savemetagraphkeys(dmg, xroot)

    # add graph
    for (gname, mg) in dmg
        xg = addelement!(xroot, "graph")
        xg["id"] = gname
        xg["edgedefault"] = is_directed(mg) ? "directed" : "undirected"

        for i in 1:nv(mg)
            xv = addelement!(xg, "node")
            if has_prop(mg, i, :id)
                xv["id"] = get_prop(mg, i, :id)
            else
                xv["id"] = "n$(i-1)"
            end
            for (k,v) in props(mg, i)
                k == :id && continue
                xel = addelement!(xv, "data", string(v))
                xel["key"] = k
            end
        end

        m = 0
        for e in Graphs.edges(mg)
            xe = addelement!(xg, "edge")

            if has_prop(mg, e, :id)
                xe["id"] = get_prop(mg, e, :id)
            else
                xe["id"] = "e$(m)"
            end

            if has_prop(mg, src(e), :id)
                xe["source"] = get_prop(mg, src(e), :id)
            else
                xe["source"] = "n$(src(e)-1)"
            end
            if has_prop(mg, dst(e), :id)
                xe["target"] = get_prop(mg, dst(e), :id)
            else
                xe["target"] = "n$(dst(e)-1)"
            end

            for (k,v) in props(mg, e)
                k == :id && continue
                xel = addelement!(xe, "data", string(v))
                xel["key"] = k
            end
            m += 1
        end
    end

    prettyprint(io, xdoc)
    return nothing
end

"""
$(TYPEDSIGNATURES) 
"""
loadgraph(io::IO, gname::String, ::GraphMLFormat, ::MGFormat) = loadmetagraphml(io, gname)
"""
$(TYPEDSIGNATURES) 
"""
loadgraphs(io::IO, ::GraphMLFormat, ::MGFormat) = loadmetagraphml_mult(io)

"""
$(TYPEDSIGNATURES) 
"""
savegraph(io::IO, g::AbstractMetaGraph, gname::String, ::GraphMLFormat) = savemetagraphml_mult(io, Dict(gname=>g))
"""
$(TYPEDSIGNATURES) 
"""
savegraph(io::IO, dg::Dict, ::GraphMLFormat, ::MGFormat) = savemetagraphml_mult(io, dg)
