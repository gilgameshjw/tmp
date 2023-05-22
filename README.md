# tmp
No code with Diagrams


### Solution



julia train.jl --path-lucidchart-csv resources/FullDemo.csv --brain-entry transliteration --path-model resources/FullDemo.dat


rm snippets/*; rm tmp.log; julia runDBGCode.jl --path-model resources/FullDemo.dat --text "abcdz hgq" >tmp.log





julia train.jl --path-lucidchart-csv resources/FullDemoWithTest.csv --brain-entry transliteration --path-model resources/FullDemoWithTest.dat

rm snippets/*;  julia runBuild.jl --path-model resources/FullDemoWithTest.dat --text "abcdz hgq"



