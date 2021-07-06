#!/usr/bin/env perl6

use Text::CodeProcessing;

sub MAIN(Str $fileName, Str :$o, Str :$rakuOutputPrompt = '# ', Str :$rakuErrorPrompt = '#ERROR: ') {
    FileCodeChunksEvaluation( $fileName, outputFileName => $o, :$rakuOutputPrompt, :$rakuErrorPrompt, :noteOutputFileName)
}
