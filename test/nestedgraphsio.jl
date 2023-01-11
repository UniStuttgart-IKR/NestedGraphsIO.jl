@testset "nestedgraphml.jl" begin
    # single graph
    fname = joinpath(testdir, "testdata", "nested.graphml")
    mg = open(fname, "r") do io
        loadgraph(io, "main-graph", GraphMLFormat(), NestedGraphFormat())
    end
    test_read_nestedgraph(mg)

    # re-read must be equal
    ftname = joinpath(testdir, "testdata", "nested_main-graph_write.graphml")
    open(ftname, "w") do io
        savegraph(io, mg, "main-graph", GraphMLFormat())
    end

    mg2 = open(ftname, "r") do io
        loadgraph(io, "main-graph", GraphMLFormat(), NestedGraphFormat())
    end
    @test ne(mg) == ne(mg2) && nv(mg) == nv(mg2) && length(mg.neds) == length(mg2.neds) && length(mg.grv) == length(mg2.grv)
    @test length(mg.grv[3].grv) == length(mg2.grv[3].grv)
    rm(ftname)
    
    # TODO multiple graphs testing
end
