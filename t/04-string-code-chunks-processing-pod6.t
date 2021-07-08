use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 6;

#============================================================
# 1 pod6 - Simple
#============================================================
my Str $code = q:to/INIT/;
=begin code
my $answer = 42;
=end code
INIT

my Str $resCode = q:to/INIT/;
=begin code
my $answer = 42;
=end code
=begin output
#OUT:42
=end output
INIT

is
        StringCodeChunksEvaluation($code, 'pod6', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42;';


#============================================================
# 2 pod6 - :results output :exports both session
#============================================================
$code = q:to/INIT/;
This is an example chunk:
=begin code
my $answer = 42;
=end code
Got it!
INIT

$resCode = q:to/INIT/;
This is an example chunk:
=begin code
my $answer = 42;
=end code
=begin output
#OUT:42
=end output
Got it!
INIT

is
        StringCodeChunksEvaluation($code, 'pod6', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'eval=TRUE: my $answer = 42;';


#============================================================
# 3 pod6 - multi-line (my)
#============================================================
$code = q:to/INIT/;
=begin code
my $ans = "43\n333\n32";
=end code
INIT

$resCode = q:to/INIT/;
=begin code
my $ans = "43\n333\n32";
=end code
=begin output
#OUT:43
#OUT:333
#OUT:32
=end output
INIT

is
        StringCodeChunksEvaluation($code, 'pod6', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $ans = "43\n333\n32";';


#============================================================
# 4 pod6 - multi-line (say)
#============================================================
$code = q:to/INIT/;
=begin code
say "43\n333\n32";
=end code
INIT

$resCode = q:to/INIT/;
=begin code
say "43\n333\n32";
=end code
=begin output
#OUT:43
#OUT:333
#OUT:32
=end output
INIT

is
        StringCodeChunksEvaluation($code, 'pod6', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'say "43\n333\n32";';


#============================================================
# 5 pod6 - multi-line (say) one prompt
#============================================================
$code = q:to/INIT/;
=begin code
say "43\n333\n32";
=end code
INIT

$resCode = q:to/INIT/;
=begin code
say "43\n333\n32";
=end code
=begin output
#OUT:43
333
32
=end output
INIT

is
        StringCodeChunksEvaluation($code, 'pod6', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:', :!promptPerLine),
        $resCode,
        ':!promptPerLine; say "43\n333\n32";';


#============================================================
# 6 pod6 - State
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
INIT

$resCode = q:to/INIT/;
Here is a variable:
=begin code
my $answer = 42;
=end code
=begin output
#OUT:42
=end output
Here is its value squared:
=begin code
$answer ** 2
=end code
=begin output
#OUT:1764
=end output
INIT

is
        StringCodeChunksEvaluation($code, 'pod6', evalOutputPrompt => '#OUT:', evalErrorPrompt => '#ERR:'),
        $resCode,
        'my $answer = 42; $answer ** 2';


done-testing;