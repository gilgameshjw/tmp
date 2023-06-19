
"""
PSEUDOCODE:
############

params = task
n = number of diagrams to produce


given a particular task:

0. Produce test data for the (end to end) task

1. Let the agent produce n diagrams

2. run through the agent steps as long as successful:
    * generating test data
    * generating the code
    * correct the code
    * score the substeps
    * 
        continue as long as possible 
        if not break
            save code, diagram and scores
            -> continue with the next step
        end
        -> continue with the next diagram
            
3. produce end to end results on test data and score results

4. create report

"""


#==================================================================================
        !!! WORK IN PROGRESS !!!
==================================================================================#
