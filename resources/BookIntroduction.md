# Introduction

This book discusses the use of the programming language Raku for computational workflows for prediction. 

Workflows that belong to:
-   Machine Learning
-   Scientific computing

Here we load a few packages:

```{perl6, eval=T}
use Lingua::NumericWordForms;
use Chemistry::Stoichiometry;
```

Consider examples of converting numeric word forms using the Raku package
[Lingua::NumericWordForms](https://github.com/antononcube/Raku-Lingua-NumericWordForms):

```{perl6, eval=T}
say from-numeric-word-form('one thousand and twenty three')
```

Here is another conversion from Bulgarian:

```{perl6 }
say from-numeric-word-form('две хиляди двеста и тринадесет')
```

Here is another conversion from Greek:

```{perl6, eval=T}
say from-numeric-word-form('τετρακόσια είκοσι επτά')
```

-----

Here we convert a chemical element symbols to corresponding Russian names:

```{perl6, eval=T}
chemical-element(["O", "Cl", "S"], "Russian")
```


----- 

## Sequence of cells of operations

Consider the variable:

```{perl6, eval=T}
my $answer = 42;
$answer;
```

Here is a square of it:

```{perl6, eval=T}
$answer * $answer;
```

```{perl6, eval=T}
($answer ~ " ") x 5
```

----- 

## The umbrella DSL functionality

We use the CLI script `dsl-translation` to invoke:

```shell
dsl-translation --help
```
