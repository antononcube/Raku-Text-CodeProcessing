#!/usr/bin/env perl6

use lib './lib';
use lib '.';

use Text::CodeProcessing;

## Org-mode
my Str $fileName =  $*CWD.Str ~ '/resources/' ~ 'BookIntroduction.org';

FileCodeChunksEvaluation($fileName):noteOutputFileName;

## Markdown
$fileName =  $*CWD.Str ~ '/resources/' ~ 'BookIntroduction.md';

FileCodeChunksEvaluation($fileName):noteOutputFileName;
