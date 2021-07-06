#!/usr/bin/env perl6

use lib './lib';
use lib '.';

use Text::CodeProcessing;

my Str $fileName =  $*CWD.Str ~ '/resources/' ~ 'BookIntroduction.md';

FileCodeChunksEvaluation($fileName):noteOutputFileName;