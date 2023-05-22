
#===

    Python Code:

    Can be also put in another file. or alternatively Below:

using PyCall # julia package to interact with python

py"""

latin_chars = 'abcdefghijklmnopqrstuvwxyz '

def normalise_filter_txt(txt):
    txt = txt.lower().strip()
    txt = ' '.join(txt.split())
    return ''.join([c for c in txt if c in latin_chars])

...

"""

===#


# computations state
dataSTATE = Dict{String, Any}(
            "state" => nothing,
            "brain" => nothing);


# Dictionary with commands
dicCODE = Dict{String, FunctionGenerator}()


# Node terminating computation
dicCODE["just output the result"] =
    #===
        Basic form of FunctionGenerators:
            d: data
            e: dicBRAINS
            f: df_Nodes

        Inputs and Outputs are specified
        :in => "l_transliterated" # list of
        :out => "res" # field expected at end of (sub)sequence
    ===#
    FunctionGenerator((d,e=nothing,f=nothing) ->
        begin
            d["res"] = d["txt"]
            d
        end, # identity
        Dict(:in => ["txt"], :out => ["res"]),
        Dict(:tests => [(Dict("txt" => "blabla"), Dict("res" => "blabla")),
                        (Dict("txt" => "radwasdcs"), Dict("res" => "radwasdcs"))]))


dicCODE["bind transliterated words together"] =
    #===    ===#
    FunctionGenerator((d,e=nothing,f=nothing) ->
        (d["txt"] = join(d["l_transl_wrds"], "");
         d),
        Dict(:in => ["l_transl_wrds"], :out => ["txt"]),
        Dict(:tests => [(Dict("l_transl_wrds" => ["b", "b"]), Dict("txt" => "b b")),
                        (Dict("l_transl_wrds" => ["r", "a"]), Dict("txt" => "r a")),
                        (Dict("l_transl_wrds" => []), Dict("txt" => "")),
                        (Dict("l_transl_wrds" => ["rr"]), Dict("txt" => "rr")),
                        (Dict("l_transl_wrds" => ["rvy", "a", "die"]), Dict("txt" => "rvy a die"))]))

dicCODE["process each word with #mapping"] =
    FunctionGenerator((d,e=nothing,f=nothing) ->
        begin
            d["l_transl_wrds"] =
            map(wrd ->
                begin
                    dd = copy(dataSTATE)
                    dd["wrd"] = wrd
                    interfaceName = "mapping"
                    node = e[interfaceName]
                    runAgent(node, e, f, dd) # jair
                end,
                d["l_wrds"])
                d
        end,
            Dict(:in => ["l_wrds"],
                 :out => ["l_transl_wrds"]),
            Dict(:tests => nothing))

dicCODE["has word the char z? return yes or no string"] =
    FunctionGenerator((d,e=nothing,f=nothing) ->
        (d["state"] = occursin("z", d["wrd"]) ?
                    "yes" : "no";
         d),
         Dict(:in => ["wrd"], :out => ["wrd", "state"]),
         Dict(:tests => [(Dict("wrd" => "slsls"), Dict("state" => "no")),
                         (Dict("wrd" => "slzls"), Dict("state" => "yes")),
                         (Dict("wrd" => ""), Dict("state" => "no"))]))


dicCODE["map z to @"] =
    FunctionGenerator((d,e=nothing,f=nothing) ->
        (wrd = d["wrd"];
         d["wrd"] =
            read(pipeline(`echo $wrd`, `sed s/z/@/g`), String);
         d),
         Dict(:in => ["wrd"], :out => ["wrd"]),
         Dict(:tests => [(Dict("wrd" => "slsls"), Dict("wrd" => "slsls")),
                         (Dict("wrd" => "slzls"), Dict("wrd" => "sl@ls")),
                         (Dict("wrd" => ""), Dict("wrd" => "")),
                         (Dict("wrd" => "z"), Dict("wrd" => "@"))]))


using PyCall

py"""
d_maps = {'z': 'a',
          'y': 'x',
          'x': 'w',
          'w': 'v',
          'v': 'u',
          'u': 't',
          't': 's',
          's': 'r',
          'r': 'q',
          'q': 'p',
          'p': 'o',
          'o': 'n',
          'n': 'm',
          'm': 'l',
          'l': 'k',
          'k': 'j',
          'j': 'i',
          'i': 'h',
          'h': 'g',
          'g': 'f',
          'f': 'e',
          'e': 'd',
          'd': 'e',
          'c': 'd',
          'b': 'c',
          'a': 'b',
          '@': 'a'}

"""

dicCODE["map all characters of the string to the next one in the alphabet and map the character @ to a"] =
    #===
        We use a python dictionary to generate the mappings.
        Alternative snippet structure with begin; end;
    ===#
    FunctionGenerator((d,e=nothing,f=nothing) ->
        begin
            wrd = d["wrd"]
            d["res"] = join([py"""d_maps"""[string(c)] for c in wrd
                     if c!='\n'])
                         d
        end,
            Dict(:in => ["wrd"], :out => ["res"]),
            Dict(:tests => [(Dict("wrd" => "a"), Dict("res" => "b")),
                            (Dict("wrd" => "z"), Dict("res" => "a")),
                            (Dict("wrd" => "zz"), Dict("res" => "aa")),
                            (Dict("wrd" => "zzz"), Dict("res" => "aaa")),
                            (Dict("wrd" => "b"), Dict("res" => "c"))]))

py"""
latin_chars = 'abcdefghijklmnopqrstuvwxyz '

#def normalise_filter_txt(txt):
#    txt = txt.lower().strip()
#    txt = ' '.join(txt.split())
#    return ''.join([c for c in txt if c in latin_chars])


def normalise_filter_txt(txt):
    txt = txt.lower().strip()
    txt = ''.join(c for c in txt if c.lower() in latin_chars)
    txt = ' '.join(txt.split())
    return {'txt': txt}

"""

"""
dicCODE["normalize the text!"] =
    #===
        Example calling a python function
    ===#
    FunctionGenerator((d,e=nothing,f=nothing) ->
        (d["txt"] = py" " "normalise_filter_txt" " "(d["txt"]);
         d),
            Dict(:in => ["txt"], :out => ["txt"]),
            Dict(:tests => [(Dict("txt" => "A Vv"), Dict("txt" => "a vv")),
                            (Dict("txt" => "A. ,;Vv"), Dict("txt" => "a vv")),
                            (Dict("txt" => "A. #?! ,;Vv"), Dict("txt" => "a vv")),
                            (Dict("txt" => "£@~]{.,:;"), Dict("txt" => ""))]))
"""

dicCODE["normalize the text!"] =
    #===
        Example calling a python function
    ===#
    FunctionGenerator((d,e=nothing,f=nothing) ->
        (d["txt"] = py"""normalise_filter_txt"""(d["txt"]); #error();
         d),
            Dict(:in => ["txt"], :out => ["txt"]),
            Dict(:tests => [(Dict("txt" => "A Vv"), Dict("txt" => "a vv")),
                            (Dict("txt" => "A. ,;Vv"), Dict("txt" => "a vv")),
                            (Dict("txt" => "A. #?! ,;Vv"), Dict("txt" => "a vv")),
                            (Dict("txt" => "£@~]{.,:;"), Dict("txt" => ""))]))


dicCODE["tokenize the text!"] =
#===
    Example running julia code
        Function
            :in => txt
            :out => l_wrds
===#
FunctionGenerator((d,e=nothing,f=nothing) ->
    (d["l_wrds"] = split(d["txt"]);
     d),
        Dict(:in => ["txt"], :out => ["l_wrds"]),
        Dict(:tests => [(Dict("txt" => "a b c"), Dict("l_wrds" => ["a", "b", "c"])),
                        (Dict("txt" => "a b c d"), Dict("l_wrds" => ["a", "b", "c", "d"])),
                        (Dict("txt" => "a b c d e"), Dict("l_wrds" => ["a", "b", "c", "d", "e"])),
                        (Dict("txt" => ""), Dict("l_wrds" => []))]))
