#!/usr/bin/env perl6

# The initial version of the code was taken from : https://stackoverflow.com/a/57128623

use v6;
use Text::CodeProcessing::REPLSandbox;

#| Markdown code chunk ticks
constant $mdTicks = '```';

#| Markdown code chunk search regex
my regex Search {
    $mdTicks '{' \h* $<lang>=('perl6' | 'raku') [\h+ ('evaluate' | 'eval') \h* '=' \h* $<evaluate>=(TRUE | T | FALSE | F) | \h*] '}'
    $<code>=[<!before $mdTicks> .]*
    $mdTicks
}

#| Markdown replace sub
sub Replace ($sandbox, $/, Str :$rakuOutputPrompt = '# ', Str :$rakuErrorPrompt = '#ERROR: ') {
    $mdTicks ~ $<lang> ~ $<code> ~ $mdTicks ~
            (!$<evaluate> || $<evaluate>.Str (elem) <TRUE T>
                    ?? "\n" ~ $mdTicks ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, $rakuOutputPrompt,
                            $rakuErrorPrompt) ~ $mdTicks
                    !! '');
}

#| Evaluation of code chunk
sub CodeChunkEvaluate ($sandbox, $code, $rakuOutputPrompt, $rakuErrorPrompt) is export {

    my $out;

    my $*OUT = $*OUT but role {
        method print (*@args) {
            $out ~= @args
        }
    }

    $sandbox.execution-count++;
    my $p = $sandbox.eval($code.Str, :store($sandbox.execution-count));

    #    say '$p.output : ', $p.output;
    #    say '$p.output-raw : ', $p.output-raw;
    #    say '$p.exception : ', $p.exception;

    ## Result with prompts
    ($p.exception ?? $rakuErrorPrompt ~ $p.exception ~ "\n" !! '') ~ $rakuOutputPrompt ~ ($out // $p.output ~ "\n")
}

#| The main program
sub FileCodeChunksEvaluation(Str $fileName,
                              Str :$outputFileName,
                              Str :$rakuOutputPrompt = '# ',
                              Str :$rakuErrorPrompt = '#ERROR: ',
                              Bool :$noteOutputFileName = False) is export {

    ## Determine the output file name
    my Str $fileNameNew;

    with $outputFileName {
        $fileNameNew = $outputFileName
    } else {
        ## If the input file name has extension that is one of <md MD Rmd>
        ## then insert "_weaved" before the extension.
        if $fileName.match(/ .* ['.md' | '.MD' | '.Rmd'] $ /) {
            $fileNameNew = $fileName.subst(/ $<name> = (.*) '.' $<ext> = ('md' | 'MD' | 'Rmd') $ /, ->
            $/ { $<name> ~ '_weaved.' ~ $<ext> });
        } else {
            $fileNameNew = $fileName ~ '_weaved';
        }
    }

    if $noteOutputFileName {
        note "Output file is $fileNameNew" unless $outputFileName;
    }

    ## Create a sandbox
    my $sandbox = REPLSandbox.new();

    ## Process code blocks (weave output)
    spurt
            $fileNameNew,
            slurp($fileName)
                    .subst: &Search, -> $s { Replace($sandbox, $s, :$rakuOutputPrompt, :$rakuErrorPrompt) }, :g;
}