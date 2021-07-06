#!/usr/bin/env perl6

use lib './lib';
use lib '.';

use Text::CodeProcessing;

## Markdown
my $fileName =  $*CWD.Str ~ '/resources/' ~ 'BookIntroduction.md';

FileCodeChunksEvaluation($fileName):noteOutputFileName;

## Org-mode
$fileName =  $*CWD.Str ~ '/resources/' ~ 'BookIntroduction.org';

FileCodeChunksEvaluation($fileName):noteOutputFileName;

## Pod6
$fileName =  $*CWD.Str ~ '/resources/' ~ 'BookIntroduction.pod6';

FileCodeChunksEvaluation($fileName):noteOutputFileName;
