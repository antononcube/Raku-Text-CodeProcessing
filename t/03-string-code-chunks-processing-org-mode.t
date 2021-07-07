use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 4;

#============================================================
# 1 org-mode - Simple
#============================================================
my Str $code = q:to/INIT/;
#+BEGIN_SRC raku
my $answer = 42;
#+END_SRC
INIT

my Str $resCode = q:to/INIT/;
#+BEGIN_SRC raku
my $answer = 42;
#+END_SRC
#+RESULTS:
: 42

INIT

is
        StringCodeChunksEvaluation($code, 'org-mode', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42;';


#============================================================
# 2 org-mode - :results output :exports both session
#============================================================
$code = q:to/INIT/;
#+BEGIN_SRC raku :results output :exports both :session
my $answer = 42;
#+END_SRC
INIT

$resCode = q:to/INIT/;
#+BEGIN_SRC raku :results output :exports both :session
my $answer = 42;
#+END_SRC
#+RESULTS:
: 42

INIT

is
        StringCodeChunksEvaluation($code, 'org-mode', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'eval=TRUE: my $answer = 42;';


#============================================================
# 3 org-mode - :results output :exports both session
#============================================================
$code = q:to/INIT/;
This is an example chunk:
#+BEGIN_SRC raku :results output :exports both :session
my $answer = 42;
#+END_SRC
Got it!
INIT

$resCode = q:to/INIT/;
This is an example chunk:
#+BEGIN_SRC raku :results output :exports both :session
my $answer = 42;
#+END_SRC
#+RESULTS:
: 42

Got it!
INIT

is
        StringCodeChunksEvaluation($code, 'org-mode', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'eval=TRUE: my $answer = 42;';


#============================================================
# 4 org-mode - State
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

INIT

is
        StringCodeChunksEvaluation($code, 'org-mode', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42; $answer ** 2';


done-testing;