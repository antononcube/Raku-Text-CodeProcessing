use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 3;

#============================================================
# 1 markdown
#============================================================
my Str $code = q:to/INIT/;
Here is a variable:
```raku
my $answer = 42;
```
Here is its value squared:
```raku
$answer ** 2
```

Here are cubed and cubed of the squared:
```{raku}
$answer ** 3
$answer ** 2 ** 3
```
INIT


my Str $resCode = q:to/INIT/;
Here is a variable:
```raku
my $answer = 42;
```
```
# OUTPUT := 42
```
Here is its value squared:
```raku
$answer ** 2
```
```
# OUTPUT := 1764
```

Here are cubed and cubed of the squared:
```{raku}
$answer ** 3
$answer ** 2 ** 3
```
```
# FAILURE := Two terms in a row across lines (missing semicolon or comma?)
# OUTPUT := Nil
```
INIT


my $doc-file = $*TMPDIR.child("temp_doc.md");
$doc-file.spurt($code);

FileCodeChunksEvaluation( $doc-file.Str, evalOutputPrompt => '# OUTPUT := ', evalErrorPrompt => '# FAILURE := ' );

my $md-file-new = $*TMPDIR.child("temp_doc_woven.md");

my $md-new-code = slurp($md-file-new);

is trim($md-new-code), trim($resCode), 'markdown';


#============================================================
# 2 org-mode
#============================================================
$code = q:to/INIT/;
Here is a variable:
#+BEGIN_SRC raku
my $answer = 42;
#+END_SRC
Here is its value squared:
#+BEGIN_SRC raku
$answer ** 2
#+END_SRC

Here are cubed and cubed of the squared:
#+BEGIN_SRC raku
$answer ** 3
$answer ** 2 ** 3
#+END_SRC
INIT


$resCode = q:to/INIT/;
Here is a variable:
#+BEGIN_SRC raku
my $answer = 42;
#+END_SRC
#+RESULTS:
: 42

Here is its value squared:
#+BEGIN_SRC raku
$answer ** 2
#+END_SRC
#+RESULTS:
: 1764


Here are cubed and cubed of the squared:
#+BEGIN_SRC raku
$answer ** 3
$answer ** 2 ** 3
#+END_SRC
#+RESULTS:
:ERROR: Two terms in a row across lines (missing semicolon or comma?)
: Nil
INIT


$doc-file = $*TMPDIR.child("temp_doc.org");
$doc-file.spurt($code);

# Note that instead of setting:
#   evalOutputPrompt => ': ', evalErrorPrompt => ':ERROR: '
# we rely on the automatic prompt assignment.
FileCodeChunksEvaluation( $doc-file.Str, outputFileName => $doc-file.Str.subst('.org', '_new.org') );

my $org-file-new = $*TMPDIR.child("temp_doc_new.org");

my $org-new-code = slurp($org-file-new);

is trim($org-new-code), trim($resCode), 'org-mode';


#============================================================
# 3 pod6
#============================================================
$code = q:to/INIT/;
Here is a variable:
=begin code
my $answer = 42;
=end code
Here is its value squared:
=begin code
$answer ** 2
=end code

Here are cubed and cubed of the squared:
=begin code
$answer ** 3
$answer ** 2 ** 3
=end code
INIT


$resCode = q:to/INIT/;
Here is a variable:
=begin code
my $answer = 42;
=end code
=begin output
# 42
=end output
Here is its value squared:
=begin code
$answer ** 2
=end code
=begin output
# 1764
=end output

Here are cubed and cubed of the squared:
=begin code
$answer ** 3
$answer ** 2 ** 3
=end code
=begin output
#ERROR: Two terms in a row across lines (missing semicolon or comma?)
# Nil
=end output
INIT

$doc-file = $*TMPDIR.child("temp_doc.pod6");
$doc-file.spurt($code);

FileCodeChunksEvaluation( $doc-file.Str );

my $pod6-file-new = $*TMPDIR.child("temp_doc_woven.pod6");

my $pod6-new-code = slurp($pod6-file-new);

is trim($pod6-new-code), trim($resCode), 'org-pod6';


done-testing;