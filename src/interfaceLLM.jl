
#=========================================================
    LIBRARY INTERFACING WITH LLM (CHATGPT FOR V0.0)
=========================================================#


"""
    query chat gpt 
        -> String
"""
function queryChatgpt(prompt, 
                      engine="text-davinci-003")
    mssgs = openai.Completion[:create](
        engine = engine,
        prompt = prompt,
        max_tokens = 1024,
        n = 1,
        #stop = None,
        temperature = 0.00
    )
    mssgs["choices"][1]["text"]
end


"""
    Runs single Test and collect tuple data if fails.
"""
function runSingleTest(fct::Function,
                       dataList, 
                       dicBRAINS::Dict{String, Node},
                       dfNodes::DataFrame,
                       data::Union{Nothing, Any})

    # placeholder for data 
    testErrorData = Vector{Tuple{Dict{String, Any}, Dict{String, Any}, Dict{String, Any}}}()

    # runs over test data list
    if !isnothing(dataList[:tests])
    
        for dataTestSample in dataList[:tests]

            dataIn = dataTestSample[1]
            dataOut = dataTestSample[2]
        
            # populate data with test data fields
            for (k, v) in dataIn
                data[k] = v
            end

            # collect result
            dataResu = fct(data, dicBRAINS, dfNodes)

            # compare and collect data for failed tests
            for (k, v) in dataOut

                if dataResu[k] != v

                    push!(testErrorData,
                        (dataIn, dataOut, 
                         Dict(k => dataResu[k] for k in keys(dataOut))))
 
                end
            
            end

            # if !stateCompute
            #    println("#################")
            ##    println("for the input ", dataIn, 
            #            "\nthe code is giving wrong result: ", dataResu, 
            #            "\ninstead of ", dataOut)
            #    println("#################")
            #end

        end
    end

    testErrorData

end


"""
    Given a command, tests are ran and if they fail, correction are made. 
"""
function runTests(command::String,  
                  dataList,
                  dicBRAINS::Dict{String, Node},
                  dfNodes::DataFrame,
                  data::Union{Nothing, Any})

    # loop over global number of correction iterations
    for iteration = 1:numberCorrectionLoops

        # collect fct & data 
        fct = dicCODE[command].fct
        testErrorData = runSingleTest(fct,
                                      dataList, 
                                      dicBRAINS, 
                                      dfNodes,
                                      data)

        # if test errors list not []                  
        if length(testErrorData) > 0

            @warn "runs improvement iter #$iteration for command: ", command
            updateFunctionOneStep(command,
                                  testErrorData, 
                                  dicCODE, 
                                  dicTESTS, 
                                  codeDir, 
                                  "text-davinci-003")
        else

            break

        end
    
    end

end

