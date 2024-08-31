@testset "metagraphml.jl" begin
    # single graph
    fname = joinpath(testdir, "testdata", "mlattrs.graphml")
    mg = open(fname, "r") do io
        loadgraph(io, "main-graph", GraphMLFormat(), MGFormat())
    end
    test_read_metagraph(mg)

    # re-read must be equal
    ftname = joinpath(testdir, "testdata", "mlattrs_main-graph_write.graphml")
    savegraph(ftname, mg, "main-graph", GraphMLFormat())
    mg2 = open(ftname, "r") do io
        loadgraph(io, "main-graph", GraphMLFormat(), MGFormat())
    end
    @test mg == mg2 && mg.vprops == mg2.vprops && mg.eprops == mg2.eprops
    rm(ftname)
    
    # multiple graphs
    dmg = open(fname, "r") do io
        loadgraphs(io, GraphMLFormat(), MGFormat())
    end
    
    @test length(dmg) == 2
    test_read_metagraph(dmg["main-graph"])
    
    # re-read must be equal
    ftname = joinpath(testdir, "testdata", "mlattrs_write.graphml")
    open(ftname, "w") do io
        savegraph(io, dmg, GraphMLFormat(), MGFormat())
    end
    dmg2 = open(ftname, "r") do io
        loadgraphs(io, GraphMLFormat(), MGFormat())
    end
    for (dmg_g, dmg2_g) in zip(values(dmg), values(dmg2))
        @test dmg_g == dmg2_g && dmg_g.vprops == dmg2_g.vprops && dmg_g.eprops == dmg2_g.eprops
    end
    rm(ftname)

   # ITZ graphml
    ftname = joinpath(testdir, "testdata", "ITZ_Aarnet.graphml")
    dmg2 = open(ftname, "r") do io
        loadgraphs(io, GraphMLFormat(), MGFormat())
    end
end
