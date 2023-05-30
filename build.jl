
#=========================================================
    SCRIPT RUNNING THE PARSING & PROCESSING OF CSVS
=========================================================#


using Graphs
using CSV
using JSON
using DataFrames
using ArgParse
using Serialization


include("src/Graphs.jl")
include("src/Agent.jl")
include("src/Rules.jl")


"""
    Parse command line arguments
"""
function parse_commandline()

    s = ArgParseSettings()

    @add_arg_table! s begin

        "--path-lucidchart-csv"
            help = "path to the graph csv"
        "--dir-path-lucidchart-csv"
            help = "path to directory containing graph csv's"
        "--brain-entry"
            help = "brain entry"
        "--path-model"
            help = "path to the train model, e.g. resources/model.dat"

    end

    parse_args(s)

end


# Set up variables
parsedArgs = parse_commandline()

modelName = parsedArgs["path-model"]
brainEntry = lowercase(parsedArgs["brain-entry"])
entryFound = false

# Parse csv data
df = Nothing
S = 0

# Parse either directory (with multiple csv's) or single csv
if !isnothing(get(parsedArgs, "dir-path-lucidchart-csv", nothing))

    # Parse directory and extract+process all csv's
    @info "PROCESSING DIR::", parsedArgs["dir-path-lucidchart-csv"]
    dirName = parsedArgs["dir-path-lucidchart-csv"]

    df = filter(s -> s[end-3:end] == ".csv", readdir(parsedArgs["dir-path-lucidchart-csv"])) |>
        (gNs -> map(gN -> (@info "process file::", gN;
                           df = DataFrame(CSV.File(dirName*gN));
                           global S;
                           df[!,"Id"] = map(d -> d + S, df[!,"Id"]);
                           df[!,"Line Destination"] = map(d -> ismissing(d) ? d : d + S,
                                                          df[!,"Line Destination"]);
                           df[!,"Line Source"] = map(d -> ismissing(d) ? d : d + S,
                                                     df[!,"Line Source"]);
                           S = S + size(df)[1];
                           df),
                    gNs)) |>
            (vgNs -> vcat(vgNs...))

else

    # Parse single file
    @info "PROCESSING FILE::", parsedArgs["path-lucidchart-csv"]
    df = DataFrame(CSV.File(parsedArgs["path-lucidchart-csv"]))

end


# Preprocess Nodes
df[!,"Label"] = map(x -> ismissing(x) ? Missing : lowercase(x), df[!,"Text Area 1"])

# Build up data structure
dfNodes = filter(row -> row.Name in ["Decision", "Process", "Terminator"], df)
dfArrows = filter(row -> row.Name in ["Line"], df);
dfBrains = filter(row -> row.Name in ["Curly Brace Note"], df);
dicTESTS =

    if "Test Data" in names(df)

        filter(kv -> Bool(!ismissing(kv[1])), 
           collect(zip(df[:,"Text Area 1"], df[:,"Test Data"]))) |>
            (KVs -> map(kv -> (kv[1] |> lowercase, Dict(:tests => kv[2] |> JSON.parse)),
                        KVs)) |> Dict

    else

        @warn "tests were not found in the dataframe"
        nothing

    end

dicBRAINS = Dict{String, Node}()

brainsList = dfBrains[!, "Label"] |> unique


if !(brainEntry in brainsList)

    @warn "brain-entry not found in graph!
              (notice that lowercases of node names are taken)"
    exit()

end

for brain in brainsList

    @info "build brain: ", brain

    # try

        dicBRAINS[brain] = get_node(brain, dfBrains) |>
                (D ->
                    (n=Node(D, nothing); n.x[:depth]=0; n)) |>
                    (N ->
                         createTree(N, dfNodes, dfArrows, dfBrains))

    # catch

    #    @error "error! brain : ", brain

    # end

end

# Serialize data
serialize(modelName, 
          Dict(:dicBrains => dicBRAINS,
               :dfNodes => dfNodes,
               :entry => brainEntry,
               :tests => dicTESTS))
               
@info "data saved to: ", modelName
