# NO CODE SOFTWARE FROM GRAPHS


### Task & Pbm
Automatised code generation from diagrams using Large Language Models:

* The basis for the code is a combination of diagrams with nodes described with natural language snippets and test data
* Automatised code generation is realised in interaction with large language models
 

### Solution
In a nutshell:

1. Diagram structure is being parsed.

2. A conversation with the language model is used to generate the necessary code snippets.

3. Data snippets are used to stabilise the code, by looping over the errors and asking the language model to improve.

### Simple Task

We choose as simple task the transformation of any latine characters into their next character in the alphabet.
Other characters are just simply filtered out. 

examples:
* `abc -> bcd`
* `z -> a`
* `nmkza rfa -> omlab sgb`
  

### Diagrams

The task above has been implemented in lucidchart into the following subdiagrams:

`ls resources/FullDemo.p*
resources/FullDemo.pdf  resources/FullDemo.jpg`


![Alt text](/resources/FullDemo.jpg "a title")

Notice that **Transliteration** is the entry point.


### Run

1. Parse the diagram and create a computerised version:
`julia build.jl --path-lucidchart-csv resources/FullDemoWithTest.csv --brain-entry transliteration --path-model resources/FullDemoWithTest.dat`

2. run or and generate code (if files not available in `/snippets`):
`julia run.jl --path-model resources/FullDemoWithTest.dat --text "abcdz hgq"`

### Test Data

Test Data is used to finetune the generated code and make sure it works as expected. 
See **Test Data** in:
`resources/FUllDemoWithTestData.csv`.
