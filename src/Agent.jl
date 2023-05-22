
#=========================================================
    LIBRARY WITH AGENTS AND ITS LOGIC
=========================================================#


"""
    Solve single node making calls to functions interfacing LLMs.
"""
function processNode(node::Node,
                     dicBRAINS::Dict{String, Node},
                     dfNodes::DataFrame,
                     data::Union{Nothing, Any})

    command = node.x[:Label]

    # check that command ⊂ (contained by) dicCODE.
    if haskey(dicCODE, command)

        # check that fields in data are within ⊂ node's metadata.
        states = collect(keys(data))
        unrecFields =
            filter(s -> !(s in states), 
                   dicCODE[command].meta[:in])

        if unrecFields != String[]

            @error string("command :: ", command,
                " fields not recognised:: ", unrecFields)
            return nothing

        end

        # symbol # is used to reference subtree's.
        if !occursin("#", command)

            # generate initial function with chatgpt
            generateFunctionCode(command,
                                        dicCODE, 
                                        dicTESTS)
            # run tests
            runTests(command,
                     dicCODE[command].tests, 
                     dicBRAINS, 
                     dfNodes, 
                     copy(data))

        else

            runSubTree(command,
                       dicCODE, 
                       dicTESTS)

        end

        dicCODE[command].fct(data, 
                             dicBRAINS, 
                             dfNodes)

    else

        @error string("command not found/built :: ", command)
        nothing

    end

end


"""
    Main function processing a decision tree, calling the node resolution 
        and also itself, when entering a subtree.
"""
function runAgent(node::Node,
                  dicBRAINS::Dict{String, Node},
                  dfNodes::DataFrame,
                  data::Union{Nothing, Any})
    
    name = node.x[:Label]
    while !isnothing(node)
        
        label = node.x[:Label]
        
        # If label in dicBrain, it means we need to run a full subtree.
        if haskey(dicBRAINS, label)
        
            @info "brain name ::> ", label
            graph = dicBRAINS[label].children[1]
        
            data = runAgent(graph,
                         dicBRAINS,
                         dfNodes,
                         data)
            
            data["brain"] = name
            @info "back to brain:: ", name
     
        else
        
            @info "node::> ", label
            @info "data::> ", data
            data = processNode(node, 
                               dicBRAINS, 
                               dfNodes, 
                               data) 
            
        end
        
        node = 
            if !isnothing(node.children)
                
                if length(node.children) > 1

                    state = data["state"]
                    @info "response::> ", state
                    id = node.x[:map][state]
                    node.children[id]

                else

                    node.children[1]

                end
            
                node.children[1]
            
            end
        
    end

    haskey(data, "res") ? data["res"] : data

end

