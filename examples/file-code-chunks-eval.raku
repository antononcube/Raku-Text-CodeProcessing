#!/usr/bin/env perl6

use Text::CodeProcessing;

sub MAIN(Str $fileName, Str :$o, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ') {
    FileCodeChunksEvaluation( $fileName, outputFileName => $o, :$evalOutputPrompt, :$evalErrorPrompt, :noteOutputFileName)
}
