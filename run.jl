
#=========================================================
    SCRIPT RUNNING/GENERATING THE CODE
=========================================================#


using Graphs
using CSV
using DataFrames
using ArgParse
using Serialization
using YAML
using PyCall


include("src/Graphs.jl")
include("src/Agent.jl")
include("src/Utilities.jl")
include("src/interfaceLLM.jl")


"""
    Parse command line arguments
"""
function parse_commandline()

    s = ArgParseSettings()

    @add_arg_table! s begin

        "--path-model"
            help = "path to the train model"
        "--text"
            help = "farsi text to be transliterated"

    end

    parse_args(s)

end


# parse commands
parsedArgs = parse_commandline()

# load brain data
pathModel = parsedArgs["path-model"]
data = deserialize(pathModel)

# parse config & set up global params
config = YAML.load_file("config.yml")
codeDir = config["codeDir"]
openaiKey = config["openaiKey"]
numberCorrectionLoops = config["numberCorrectionLOOPS"]
generateJuliaCode = config["generateJuliaCode"]


# start open ai
openai = pyimport("openai")
openai.api_key = openaiKey

# set up players
entryBrain = data[:entry]
dicBRAINS = data[:dicBrains]
dfNodes = data[:dfNodes]
dicTESTS = data[:tests]
dicCODE = data[:dicCode]
graph = dicBRAINS[entryBrain]

# data to be transformed within the tree flows
data = Dict{String, Any}(
            "txt" => parsedArgs["text"],
            "state" => nothing, # used for messages back to system
            "brain" => entryBrain)

# run agent
result = runAgent(graph.children[1],
                  dicBRAINS, 
                  dfNodes, 
                  data) 

# output final data
@info "result" result


"####################################################################" |> println
"###########################  END ###################################" |> println
"####################################################################" |> println
