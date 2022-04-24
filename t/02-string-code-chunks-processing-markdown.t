use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 9;

#============================================================
# 1 markdown - Simple
#============================================================
my Str $code = q:to/INIT/;
```{raku}
my $answer = 42;
```
INIT

my Str $resCode = q:to/INIT/;
```{raku}
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
```{raku, eval=TRUE}
my $answer = 42;
```
INIT

$resCode = q:to/INIT/;
```{raku, eval=TRUE}
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
```{raku, eval=FALSE}
my $answer = 42;
```
INIT

$resCode = q:to/INIT/;
```{raku, eval=FALSE}
my $answer = 42;
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'eval=FALSE: my $answer = 42;';


#============================================================
# 4 markdown - no {}
#============================================================
$code = q:to/INIT/;
```raku
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
        'eval=FALSE: my $answer = 42;';


#============================================================
# 5 markdown - multi-line (my)
#============================================================
$code = q:to/INIT/;
```raku
my $ans = "43\n333\n32";
```
INIT

$resCode = q:to/INIT/;
```raku
my $ans = "43\n333\n32";
```
```
#OUT:43
#OUT:333
#OUT:32
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $ans = "43\n333\n32";';


#============================================================
# 6 markdown - multi-line (say)
#============================================================
$code = q:to/INIT/;
```raku
say "43\n333\n32";
```
INIT

$resCode = q:to/INIT/;
```raku
say "43\n333\n32";
```
```
#OUT:43
#OUT:333
#OUT:32
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'say "43\n333\n32";';


#============================================================
# 7 markdown - multi-line (say) one prompt
#============================================================
$code = q:to/INIT/;
```raku
say "43\n333\n32";
```
INIT

$resCode = q:to/INIT/;
```raku
say "43\n333\n32";
```
```
#OUT:43
333
32
```
INIT

is
        StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:', :!promptPerLine),
        $resCode,
        ':!promptPerLine; say "43\n333\n32";';


#============================================================
# 8 markdown - State
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
```{raku}
my $answer = 42;
```
```
#OUT:42
```
```{raku}
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
# 9 markdown - State incomplete code
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
```{raku}
my $answer = 42 *
```
```
#ERR:Missing required term after infix
#OUT:Nil
```
```{raku}
$answer ** 2
```
```
#ERR:Variable '$answer' is not declared
#OUT:Nil
```
INIT

my $resCodeUpdate = $resCode.subst('Variable \'$answer\' is not declared',
        'Variable \'$answer\' is not declared. Perhaps you forgot a \'sub\' if this was intended to be part of a signature?');

my $resRun = StringCodeChunksEvaluation($code, 'markdown', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:');

is $resRun eq $resCode || $resRun eq $resCodeUpdate,
        True,
        'my $answer = 42 *; $answer ** 2';


done-testing;