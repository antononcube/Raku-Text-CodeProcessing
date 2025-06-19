# Raku Text::CodeProcessing

[![Build Status](https://app.travis-ci.com/antononcube/Raku-Text-CodeProcessing.svg?branch=main)](https://app.travis-ci.com/github/antononcube/Raku-Text-CodeProcessing)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

## In brief

The main goal of this package is to facilitate 
[Literate Programming](https://en.wikipedia.org/wiki/Literate_programming)
with Raku.

The package has functions and a script for the evaluations of
code chunks in documents of different types (like 
[Markdown](https://daringfireball.net/projects/markdown/), 
[Org Mode](https://orgmode.org), 
[Pod6](https://docs.raku.org/language/pod).)

There is also a script for extracting code chunks.

------

## Installation

Package installations from both sources use [zef installer](https://github.com/ugexe/zef)
(which should be bundled with the "standard" [Rakudo](https://rakudo.org) installation file.)

To install the package from [Zef ecosystem](https://raku.land)
use the shell command:

```
zef install Text::CodeProcessing
```

To install the package from the GitHub repository use the shell command:

```
zef install https://github.com/antononcube/Raku-Text-CodeProcessing.git
```

------

## Usage

### Main function

The package provides the function `FileCodeChunksEvaluation` for the 
evaluation of code chunks in files. The first argument is a file name string:

```
FileCodeChunksEvaluation( $fileName, ... )
```
Here are the (optional) parameters:

- `Str :$outputFileName` : output file name
  
- `Str :$evalOutputPrompt = 'AUTO'` : code chunk output prompt

- `Str :$evalErrorPrompt = 'AUTO'` : code chunk error prompt

- `Bool :$noteOutputFileName = False` : whether to print out the name of the new file

- `Bool :$promptPerLine = True` : whether to put prompt to each output or error line or just the first one

When the prompt arguments are given the value `'AUTO'` then the actual prompt values are selected according to the file type:

- Markdown : `evalOutputPrompt = '# '`, `evalErrorPrompt = '#ERROR: '`

- Org-mode : `evalOutputPrompt = ': '`, `evalErrorPrompt = ':ERROR: '`

- Pod6 : `evalOutputPrompt = '# '`, `evalErrorPrompt = '#ERROR: '`

-------

## Document parameters

Documents can have a YAML header. If that header contains parameter specifications
the corresponding parameters values are replaced in the document before evaluation.

Here is a Markdown document string with an YAML header and Raku code that uses the parameters:

````
----
title: "Replacement example"
date: 2025-06-19
params:
  partSize: 0.25
  dataDirName: "~/fake-data"
  exportQ: FALSE
----

Getting data from %params<dataDirName>:

```raku
say %params<partSize>;
say (%params{"exportQ"} ?? '' !! 'do not ') ~ 'export it';
```
```
#ERROR: Variable '%params' is not declared.  Perhaps you forgot a 'sub' if this
#ERROR: was intended to be part of a signature?
# Nil
```
````

See the test file ["08-header-parameters.rakutest"](./t/08-header-parameters.rakutest) for 
more detailed examples.

**Remark:** Both forms of hashmap retrieval, `%params<partSize>` and `%params{'partSize'}`, are replaced with the corresponding parameter value.

-------

## Command Line Interface 

The package provides Command Line Interface (CLI) scripts, 
[`file-code-chunks-eval`](bin/file-code-chunks-eval) and
[`file-code-chunks-extract`](bin/file-code-chunks-extract).

Here are script invocation examples for the code chunks evaluation in a file named "doc.md":

```
file-code-chunks-eval doc.md
```

```
file-code-chunks-eval file-code-chunks-eval.raku --evalOutputPrompt="## OUTPUT :: " --evalErrorPrompt="## ERROR :: " -o=doc_newly_weaved.md doc.md
```

Here is a script invocation example for code extraction from code chunks in a file named "doc.md":

```
file-code-chunks-extract -o=doc_new_extract.md doc.md
```

If no output file name is specified then the script
[`file-code-chunks-eval`](bin/file-code-chunks-eval)
([`file-code-chunks-extract`](bin/file-code-chunks-extract))
makes a new file in the same directory with the string
"_woven" ("_tangled") inserted into the input file name.


### `file-code-chunks-eval`

```shell
file-code-chunks-eval --help
```
```
# Usage:
#   file-code-chunks-eval <inputFileName> [-o|--output=<Str>] [--eval-output-prompt|--evalOutputPrompt=<Str>] [--eval-error-prompt|--evalErrorPrompt=<Str>] [--prompt-per-line|--promptPerLine] -- Evaluates code chunks in a file. (Markdown, Org-mode, or Pod6.)
#   
#     <inputFileName>                                  Input file name.
#     -o|--output=<Str>                                Output file; if not given the output file name is the input file name concatenated with "_woven". [default: 'Whatever']
#     --eval-output-prompt|--evalOutputPrompt=<Str>    Evaluation results prompt. [default: 'Whatever']
#     --eval-error-prompt|--evalErrorPrompt=<Str>      Evaluation errors prompt. [default: 'Whatever']
#     --prompt-per-line|--promptPerLine                Should prompts be printed per line or not? [default: True]
```

### `file-code-chunks-extract`

```shell
file-code-chunks-extract --help
```
```
# Usage:
#   file-code-chunks-extract <inputFileName> [-o|--output=<Str>] -- Extract content of code chunks in a Markdown, org-mode, or Pod6 file.
#   
#     <inputFileName>      Input file name.
#     -o|--output=<Str>    Output file; if not given the output file name is the input file name concatenated with "_tangled". [default: 'Whatever']
```

### `cronify`

The script `cronify` facilitates periodic execution of a shell command (with parameters.)
It heavily borrows ideas and code from the chapter "Silent Cron, a Cron Wrapper" of the book,
"Raku Fundamentals" by Moritz Lenz, [ML1].

```shell
cronify --help
```
```
# Usage:
#   cronify [-i|--time-interval[=Int]] [-t|--total-time[=Int]] [--verbose] [<cmd> ...] -- Periodically execute given command (and arguments.)
#   
#     [<cmd> ...]                 Command and arguments to be executed periodically.
#     -i|--time-interval[=Int]    Time interval between execution starts. [default: 10]
#     -t|--total-time[=Int]       Total time for the repeated executions loop. [default: 1800]
#     --verbose                   Should execution traces be proclaimed or not? [default: False]
```

------

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
    
- [ ] TODO Add unit tests for:

  - [X] DONE Code chunks evaluation
      
  - [X] DONE Persistence of REPL state(s)
  
  - [ ] TODO REPL availability
    
  - [X] DONE File code chunks evaluation 

  - [X] DONE File code extraction from chunks 

- [X] DONE Implement handling of code chunk parameters.

- [X] DONE Shell code chunks execution.  

- [X] DONE Implement output code cell generation that is marked as being of specified language.
  - Done via the code chunk parameter `outputLang`.
  
- [X] DONE Comprehensive help for the CLI functions. 

- [X] DONE Implement document-wide, template parameters.
  - Similar to YAML .Rmd files parameters specs.
  - [X] DONE YAML header parsing and interpretation.
  - [X] DONE Parameter substitution.
    1. [X] Globally over the whole document 
    2. [ ] Per code chunk
       - This means considering inline evaluations, like \`\`\`1_000.sqrt\`\`\`.
  - [X] DONE Unit tests.
  
- [ ] TODO Implement data arguments for code chunks.
  (As in [Babel org-mode](https://orgmode.org/manual/Environment-of-a-Code-Block.html).)

- [ ] TODO Implement evaluation of Raku code chunks in Mathematica notebooks.

- [ ] TODO Make the functionalities to work with languages other than Raku.
  - This is both difficult and low priority. (Except for shell.)

- [ ] TODO Refactor the sub arguments to use kebab-case (not just camelCase.)
  - This is of _very low_ priority. 

-----

## References

### Articles

[AA1] Anton Antonov,
["Conversion and evaluation of Raku files"](https://rakuforprediction.wordpress.com/2022/11/05/conversion-and-evaluation-of-raku-files),
(2022),
[RakuForPrediction at WordPress](https://rakuforprediction.wordpress.com).

[DS1] Daniel Sockwell,
["Weaving Raku: semiliterate programming in a beautiful language"](https://www.codesections.com/blog/weaving-raku/),
(2020),
[codesections.com](https://www.codesections.com).

[SO1] Suman Khanal et al.,
["Capture and execute multiline code and incorporate result in raku"](https://stackoverflow.com/q/57127263),
(2017),
[Stack Overflow](https://stackoverflow.com).

### Books

[ML1] Moritz Lenz,
["Raku Fundamentals: A Primer with Examples, Projects, and Case Studies"](https://www.google.com/books/edition/Raku_Fundamentals/MvyRzQEACAAJ?hl=en),
2nd ed. (2020), Apress.

### Repositories

[BD1] Brian Duggan et al.,
[p6-jupyter-kernel](https://github.com/bduggan/p6-jupyter-kernel),
(2017-2020),
[GitHub/bduggan](https://github.com/bduggan).

### Videos

[AAv1] Anton Antonov,
["Conversion and evaluation of Raku files"](https://www.youtube.com/watch?v=GJO7YqjGn6o),
(2022)
[Anton Antonov's YouTube channel](https://www.youtube.com/@AAA4prediction).