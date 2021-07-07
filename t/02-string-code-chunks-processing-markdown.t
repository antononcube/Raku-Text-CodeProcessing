use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 5;

#============================================================
# 1 markdown - Simple
#============================================================
my Str $code = q:to/INIT/;
```{raku}
my $answer = 42;
```
INIT

my Str $resCode = q:to/INIT/;
```raku
my $answer = 42;
```
```
#OUT:42
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42;';


#============================================================
# 2 markdown - eval=TRUE
#============================================================
$code = q:to/INIT/;
```{raku eval=TRUE}
my $answer = 42;
```
INIT

$resCode = q:to/INIT/;
```raku
my $answer = 42;
```
```
#OUT:42
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'eval=TRUE: my $answer = 42;';


#============================================================
# 3 markdown - eval=FALSE
#============================================================
$code = q:to/INIT/;
```{raku eval=FALSE}
my $answer = 42;
```
INIT

$resCode = q:to/INIT/;
```raku
my $answer = 42;
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'eval=FALSE: my $answer = 42;';


#============================================================
# 4 markdown - State
#============================================================
$code = q:to/INIT/;
```{raku}
my $answer = 42;
```
```{raku}
$answer ** 2
```
INIT

$resCode = q:to/INIT/;
```raku
my $answer = 42;
```
```
#OUT:42
```
```raku
$answer ** 2
```
```
#OUT:1764
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42; $answer ** 2';


#============================================================
# 5 markdown - State incomplete code
#============================================================
$code = q:to/INIT/;
```{raku}
my $answer = 42 *
```
```{raku}
$answer ** 2
```
INIT

$resCode = q:to/INIT/;
```raku
my $answer = 42 *
```
```
#ERR:Missing required term after infix
#OUT:Nil
```
```raku
$answer ** 2
```
```
#ERR:Variable '$answer' is not declared
#OUT:Nil
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42 *; $answer ** 2';


done-testing;