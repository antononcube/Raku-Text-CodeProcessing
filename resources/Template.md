---
title: Numeric word forms generation (template)
author: Anton Antonov
date: 2025-06-19
params:
    sample-size: 10
    min: 100
    max: 10E5
    to-lang: "Russian"
---

Generate a list of random numbers:

```raku
use Data::Generators;

my @ns = random-real([%params<min>, %params<max>], %params<sample-size>)».floor
```

Convert to numeric word forms:

```raku
use Lingua::NumericWordForms;

.say for @ns.map({ to-numeric-word-form($_, %params<to-lang>) })
```