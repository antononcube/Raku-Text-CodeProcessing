# Raku Text::CodeProcessing

[![Build Status](https://travis-ci.com/antononcube/Raku-Text-CodeProcessing.svg?branch=main)](https://travis-ci.com/antononcube/Raku-Text-CodeProcessing)

## In brief

The main goal of this package is to facilitate 
[Literate Programming](https://en.wikipedia.org/wiki/Literate_programming)
with Raku.

The package has functions and a script for the evaluations of
code chunks in documents of different types (like 
[Markdown](https://daringfireball.net/projects/markdown/), 
[Org Mode](https://orgmode.org), 
[Pod6](https://docs.raku.org/language/pod).)

-----

## Usage

### Main function

The package provides the function `FileCodeChunksEvaluation` for the 
evaluation of code chunks in files. The first argument is a file name string:

```perl6
FileCodeChunksEvaluation( $fileName, ... )
```
Here are the (optional) parameters:

- `Str :$outputFileName` : output file name
  
- `Str :$rakuOutputPrompt = '# '` : code chunk output prompt

- `Str :$rakuErrorPrompt = '#ERROR: '` : code chunk error prompt

- `Bool :$noteOutputFileName = False` : whether to print out the name of the new file

### Script

The [directory "./examples"](./examples) has a script file, 
[`file-code-chunks-eval.raku`](./examples/file-code-chunks-eval.raku),
that can be used from the command line. 

-----

## Implementation notes

The implementation uses a greatly reduced version of the class
[`Jupyter::Kernel::Sandbox`](https://github.com/bduggan/p6-jupyter-kernel/blob/master/lib/Jupyter/Kernel/Sandbox.rakumod)
of Raku Jupyter kernel package/repository [BD1].
(See the class [REPLSandbox](./lib/Text/CodeProcessing/REPLSandbox.rakumod).)

Just using 
[`EVAL`](https://docs.raku.org/routine/EVAL), 
(as in [SO1]) did not provide state persistence between code chunks evaluations.
For example, creating and assigning variables or loading packages in the first code chunk
did not make those variables and packages "available" in the subsequent code chunks.

That problem is resolved by setting up a separate Raku REPL (sandbox) object. 

-----

## TODO

The following TODO items are ordered by priority, the most important are on top. 
 
- [X] Provide a function that works on strings.
  (By refactoring the main function `FileCodeChunksEvaluation`.)
    
- [ ] Add unit tests for:

  - [X] Code chunks evaluation
      
  - [X] Persistence of REPL state(s)
  
  - [ ] REPL availability
    
  - [ ] File code chunks evaluation 
    
- [ ] Implement evaluation of Raku code chunks in Mathematica notebooks.

- [ ] Make the functionalities to work with languages other than Raku.
  - This is both difficult and low priority.

-----

## References

[BD1] Brian Duggan et al.,
[p6-jupyter-kernel](https://github.com/bduggan/p6-jupyter-kernel),
(2017-2020),
[GitHug/bduggan](https://github.com/bduggan).

[DS1] Daniel Sockwell,
["Weaving Raku: semiliterate programming in a beautiful language"](https://www.codesections.com/blog/weaving-raku/),
(2020),
[codesections.com](https://www.codesections.com).

[SO1] Suman Khanal et al.,
["Capture and execute multiline code and incorporate result in raku"](https://stackoverflow.com/q/57127263),
(2017),
[Stack Overlow](https://stackoverflow.com).