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

is
        StringCodeChunksExtraction($code, 'markdown') ~ "\n",
        $resCode,
        'markdown';


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

is
        StringCodeChunksExtraction($code, 'org-mode') ~ "\n",
        $resCode,
        'org-mode';


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

is
        StringCodeChunksExtraction($code, 'pod6') ~ "\n",
        $resCode,
        'pod6';

done-testing;