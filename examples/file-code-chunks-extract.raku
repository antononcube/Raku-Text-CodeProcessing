#!/usr/bin/env perl6

use Text::CodeProcessing;

sub MAIN(Str $fileName, Str :$o) {
    FileCodeChunksExtraction( $fileName, outputFileName => $o, :noteOutputFileName)
}
