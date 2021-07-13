#!/usr/bin/env perl6

use Text::CodeProcessing;

sub MAIN(Str $fileName, Str :$o, Str :$evalOutputPrompt = 'AUTO', Str :$evalErrorPrompt = 'AUTO', Bool :$promptPerLine = True) {
    FileCodeChunksEvaluation( $fileName, outputFileName => $o, :$evalOutputPrompt, :$evalErrorPrompt, :noteOutputFileName, :$promptPerLine)
}
