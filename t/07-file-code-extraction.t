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
my $answer = 42;
$answer ** 2
$answer ** 3
$answer ** 2 ** 3
INIT


my $doc-file = $*TMPDIR.child("temp_doc.md");
$doc-file.spurt($code);

FileCodeChunksExtraction( $doc-file.Str );

my $md-file-new = $*TMPDIR.child("temp_doc_tangled.md");

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


$doc-file = $*TMPDIR.child("temp_doc.org");
$doc-file.spurt($code);

FileCodeChunksExtraction( $doc-file.Str, outputFileName => $doc-file.Str.subst('.org', '_new.org') );

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


$doc-file = $*TMPDIR.child("temp_doc.pod6");
$doc-file.spurt($code);

FileCodeChunksExtraction( $doc-file.Str );

my $pod6-file-new = $*TMPDIR.child("temp_doc_tangled.pod6");

my $pod6-new-code = slurp($pod6-file-new);

is trim($pod6-new-code), trim($resCode), 'org-mode';


done-testing;