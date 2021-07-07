use Test;

use lib './lib';
use lib '.';

use Text::CodeProcessing;
use Text::CodeProcessing::REPLSandbox;

plan 2;

use-ok 'Text::CodeProcessing';

use-ok 'Text::CodeProcessing::REPLSandbox';

done-testing;
