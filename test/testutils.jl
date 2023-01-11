 function test_read_metagraph(dmg)
    for v in vertices(dmg)
        if get_prop(dmg, v, :id) == "N6"
            @test get_prop(dmg, v, :VertexLabel) == "N6"
            @test get_prop(dmg, v, :xcoord) == 170
            @test get_prop(dmg, v, :ycoord) == 0
        end
    end
    for e in edges(dmg)
        if get_prop(dmg, e, :id) == "N0-N3"
            @test get_prop(dmg, e, :LinkCapacity) == 100
        end
    end
end

function test_read_nestedgraph(nmg)
    @test ne(nmg) == 12
    @test nv(nmg) == 11
    @test length(nmg.grv) == 3
    @test nmg.grv[3] isa NestedGraph
    @test length(nmg.grv[3].grv) == 2
end
