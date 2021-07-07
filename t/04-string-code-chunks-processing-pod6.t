use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 3;

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
# 3 pod6 - State
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