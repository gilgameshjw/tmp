
#=========================================================
    LIBRARY WITH UTILITIES
=========================================================#


"""
    Clean, standardize command
"""
function getFunctionName(command)

    functionName = join(split(command), "_")
    filter(x -> x in "abcdefghijklmnopqrstuvwxyz_", 
              collect(functionName)) |> String

end


"""
    preprocess command for chat gpt 
        -> String
"""
function preprocessChat(listStr2Str::Union{Vector{Any}, Vector{Tuple{String, String}}}, 
                        fileName="chats/initTMP.txt")

    txt = read(fileName, String)
    for (cmdKey, cmdValue) in listStr2Str
        txt = replace(txt, "\$"*cmdKey => cmdValue)
    end
    txt 

end


"""
    generate function code with chat gpt on a normal fashion
        -> Nothing
"""
function generateFunctionCode(command,
                              dicCODE::Dict{String, FunctionGenerator}, 
                              dicTESTS::Dict{String, Dict{Symbol}},
                              fileName="chats/initTMP.txt", 
                              dir=codeDir, 
                              engine="text-davinci-003")
    
    # create file names
    functionName = getFunctionName(command)
    fileNamePython = dir * functionName * ".py"
    fileNameJulia = dir * functionName * ".jl"

    # create txt for LLM
    txtTMP = preprocessChat([("command", command), ("name", functionName)],
                            fileName)
    txtTMP = txtTMP * "Furthermore the expected fields for the input dictionary are as follows:" * string(dicCODE[command].meta[:in])
    txtTMP = txtTMP * "\nAlso the expected fields for the output dictionary are as follows:" * string(dicCODE[command].meta[:out])
    txtTMP = txtTMP * "\nMake sure the code is running, uses {} for the dictionary format and in python and return the code only!"

    # interact with LLM and write code to file
    if !isfile(fileNamePython)
    
        answerStr = queryChatgpt(txtTMP, engine)
        open(fileNamePython, "w") do file
            write(file, answerStr)
        end
    
    end

    # convert code onto julia (using LLM) and write it to file
    if !isfile(fileNameJulia) & generateJuliaCode

        pythonCode = read(fileNamePython, String)
        # convert to julia by asking gpt-3 to do it
        query = "convert the following python code to julia: \n" * pythonCode
        juliaCode = queryChatgpt(query, engine)
        # write to file
        open(fileNameJulia, "w") do file
            write(file, juliaCode)
        end

    end

    # load python code generated above 
    @pyinclude(fileNamePython)

    # update dicCODE
    dicCODE[command] =
        FunctionGenerator((d,e=nothing,f=nothing) ->
            (d = pyeval("lambda_" * functionName * "_function")(d); d),
                dicCODE[command].meta,
                dicTESTS[command])
    
end


"""
    generate function with chat gpt
        -> Dict
"""
function generatePromptsForLLM(command,
                               inOutExpOut::Vector{Tuple{Dict{String, Any}, Dict{String, Any}, Dict{String, Any}}},
                               dicCODE::Dict{String, FunctionGenerator}, 
                               dicTESTS::Dict{String, Dict{Symbol}},
                               dir=codeDir, 
                               engine="text-davinci-003")
    
    result = Dict()
    
    functionName = getFunctionName(command)
    
    fileNamePython = dir * functionName * ".py"
    codeString = read(fileNamePython, String)
    
    txt = preprocessChat([("code", codeString)], 
                         "chats/introLearn.txt")
    
    result["intro"] = txt
    txt = preprocessChat([("name", functionName), ("command", command)], 
                         "chats/loopLearn.txt")
    
    for (i,d) in enumerate(inOutExpOut)
    
        txt = "\n" * txt * string(i) * ".\n"
        txt = txt * "for the input: "*string(d[1])*"\n"
        txt = txt * "the code is giving wrong result: "*string(d[3])*"\n"
        txt = txt * "instead of: "*string(d[2])*"\n"
    
    end
    
    txt = txt * "\n\n" * preprocessChat([],  "chats/endLearn.txt") 
    
    result["learn"] = txt
    result
        
end


"""
    Updating/improving function corresponding to a command via interacting with the LLM.
        -> Nothing
"""
function updateFunctionOneStep(command,
                               inOutExpOut::Vector{Tuple{Dict{String, Any}, Dict{String, Any}, Dict{String, Any}}},
                               dicCODE::Dict{String, FunctionGenerator}, 
                               dicTESTS::Dict{String, Dict{Symbol}},
                               dir=codeDir, 
                               engine="text-davinci-003")
    
    dicCommands = generatePromptsForLLM(command,
                                       inOutExpOut,
                                       dicCODE, 
                                       dicTESTS,
                                       dir, 
                                       engine)
    
    # gather fct name and path
    functionName = getFunctionName(command)
    fileNamePython = dir * functionName * ".py"

    # interacts with chatgpt in 2 steps: 
    #   1. intro, general intro to pbm and request
    #   2. learn and improve 
    queryIntro = dicCommands["intro"]
    query = dicCommands["learn"]

    ____ = queryChatgpt(queryIntro, engine)    
    code = queryChatgpt(query, engine)
    
    # write updated function
    open(fileNamePython, "w") do file
        write(file, code)
        # println("wrote python function")
    end
    # println("learned command: ", command)
    
end


"""
    Function generating run on subtrees
        -> Nothing
"""
function runSubTree(command,
                    dicCODE::Dict{String, FunctionGenerator}, 
                    dicTESTS::Dict{String, Dict{Symbol}})

    command = "process each word with #mapping"
    interfaceName = filter(s -> occursin("#", s), split(command))[1][2:end]


    meta = dicCODE[command].meta
    inField = meta[:in][1]
    outField = meta[:out][1]

    dicCODE[command] = FunctionGenerator((d,e=nothing,f=nothing) ->
        begin

            d[outField] =
                map(item ->
                        begin

                            dd = copy(dataSTATE)
                            node = dicBRAINS[interfaceName].children[1]
                            s = node.x[:Label]
                            itemKEY = dicCODE[s].meta[:in][1]
                            dd[itemKEY] = item
                            runAgent(node, e, f, dd)

                        end,
            d[inField])
            d
        end,

    Dict(:in => meta[:in],
         :out => meta[:out]),
    Dict(:tests => nothing))

end