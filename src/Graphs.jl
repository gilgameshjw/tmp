
#=========================================================
    LIBRARY FOR GRAPH/DIAGRAMS ENCODING
=========================================================#


"""
    Node class for Graph elements.
"""
mutable struct Node

    x::Dict
    children::Union{Vector{Node}, Nothing}

end


"""
    Function Generator:
        * fct: function itself
        * meta: metadata for the expected entries Dict(:in => ..., :end => ...)
        * tests: test data
"""
mutable struct FunctionGenerator

    fct::Union{Function, Nothing}
    meta::Union{Dict{Symbol, Vector{String}}, Dict{Symbol, Dict{String, Any}}, Nothing}
    tests::Union{Dict{Symbol, Dict{String, Any}}, Nothing}

end


"""
    Extracts node with id, from DataFrame in which nodes are stored (flattened)
"""
function get_node(id::Int64, dfNodes::DataFrame, depth::Int64=0)

    filter(row -> row.Id == id, dfNodes)[1,:] |>
        (x -> (d=Dict(pairs(x));d[:depth]=depth;d))

end


"""
    Extracts node with interfaceName, from DataFrame in which nodes are stored (flattened)
"""
function get_node(interfaceName::String, dfNodes::DataFrame, depth::Int64=0)

    filter(row -> row.Label == interfaceName, dfNodes)[1,:] |>
        (x -> (d=Dict(pairs(x));d[:depth]=depth;d))

end


"""
    Extracts children from id, from DataFrame in which nodes are stored (flattened)
"""
function get_children_ids(id::Int64, dfArrows::DataFrame)

     dfArrows[dfArrows[!,"Line Source"] .== id, :]

end


"""
    create Tree:
        build up a graph from a parsed csv file
"""
function createTree(node::Union{Node, Nothing},
                    dfNodes::DataFrame,
                    dfArrows::DataFrame,
                    dfBrains::DataFrame,
                    dicTESTS::Dict{String, Dict{Symbol, Dict{String, Any}}},
                    dicMETA::Dict{String, Dict{Symbol, Dict{String, Any}}},
                    history::Vector{Node} = Node[])

    if node != nothing

        id = node.x[:Id]
        df_ids = get_children_ids(id, dfArrows)
        node.x[:map] = size(df_ids.Label)[1] > 1 ?
                Dict(map(x -> x[2] => x[1], enumerate(df_ids.Label))) :
                nothing


        if !haskey(dicCODE, node.x[:Label]) &
                !(node.x[:Label] in dfBrains[!, "Label"])
            
            label = node.x[:Label] |> lowercase
            if dicTESTS == nothing || dicMETA == nothing
                
                dicCODE[key] = FunctionGenerator(nothing, nothing, nothing)
            
            else       

                dicCODE[label] = FunctionGenerator(nothing, 
                                                 haskey(dicTESTS, label) ? dicTESTS[label] : nothing, 
                                                 haskey(dicMETA, label) ? dicMETA[label] : nothing)
            
            end

            @warn "unimplemented Node:: Id", node.x[:Id], " Name: " , node.x[:Label]

        end

        if size(df_ids)[1] > 0

            node.children = map(ix ->

                    if ix in [n.x[:Id] for n in history]
                        
                        filter(n -> n.x[:Id] == ix, history)[end]

                    else

                        createTree(
                            Node(get_node(ix, dfNodes, node.x[:depth]+1),
                                 nothing),
                            dfNodes, dfArrows, dfBrains,
                            dicTESTS, dicMETA,
                            [history;[node]])

                    end,
                                df_ids[!,"Line Destination"])

        end

    end

    node

end

