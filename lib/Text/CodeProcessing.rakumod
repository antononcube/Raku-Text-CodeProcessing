#!/usr/bin/env perl6

# The initial version of the code was taken from : https://stackoverflow.com/a/57128623

use v6;
use Text::CodeProcessing::REPLSandbox;

#| Markdown code chunk ticks
constant $mdTicks = '```';

#| Markdown code chunk search regex
my regex MarkdownSearch {
    $mdTicks '{' \h* $<lang>=('perl6' | 'raku') [\h+ ('evaluate' | 'eval') \h* '=' \h* $<evaluate>=(TRUE | T | FALSE | F) | \h*] '}'
    $<code>=[<!before $mdTicks> .]*
    $mdTicks
}

#| Markdown replace sub
sub MarkdownReplace ($sandbox, $/, Str :$rakuOutputPrompt = '# ', Str :$rakuErrorPrompt = '#ERROR: ') {
    $mdTicks ~ $<lang> ~ $<code> ~ $mdTicks ~
            (!$<evaluate> || $<evaluate>.Str (elem) <TRUE T>
                    ?? "\n" ~ $mdTicks ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, $rakuOutputPrompt, $rakuErrorPrompt) ~ $mdTicks
                    !! '');
}

constant $orgBeginSrc = '#+BEGIN_SRC';
constant $orgEndSrc = '#+END_SRC';

#| Org-mode code chunk search regex
my regex OrgModeSearch {
    $orgBeginSrc \h* $<lang>=('perl6' | 'raku') $<ccrest>=(\V*) \v
    $<code>=[<!before $orgEndSrc> .]*
    $orgEndSrc
}

#| Org-mode replace sub
sub OrgModeReplace ($sandbox, $/, Str :$rakuOutputPrompt = '# ', Str :$rakuErrorPrompt = '#ERROR: ') {
    $orgBeginSrc ~ ' ' ~ $<lang> ~ $<ccrest> ~ "\n" ~ $<code> ~ $orgEndSrc ~
                    "\n" ~ "#+RESULTS:" ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, ': ', ':ERROR: ');
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

my %fileTypeToSearchSub =
        markdown => &MarkdownSearch,
        org-mode => &OrgModeSearch;

my %fileTypeToReplaceSub =
        markdown => &MarkdownReplace,
        org-mode => &OrgModeReplace;

#| The main program
sub FileCodeChunksEvaluation(Str $fileName,
                             Str :$outputFileName,
                             Str :$rakuOutputPrompt = '# ',
                             Str :$rakuErrorPrompt = '#ERROR: ',
                             Bool :$noteOutputFileName = False) is export {

    ## Determine the output file name and type
    my Str $fileNameNew;
    my Str $fileType;

    with $outputFileName {
        $fileNameNew = $outputFileName
    } else {
        ## If the input file name has extension that is one of <md MD Rmd>
        ## then insert "_weaved" before the extension.
        if $fileName.match(/ .* \. [ md | MD | Rmd | org ] $ /) {
            $fileNameNew = $fileName.subst(/ $<name> = (.*) '.' $<ext> = (md | MD | Rmd | org) $ /, -> $/ { $<name> ~ '_weaved.' ~ $<ext> });
        } else {
            $fileNameNew = $fileName ~ '_weaved';
        }

        if $fileName.match(/ .* \. [ md | MD | Rmd ] $ /) { $fileType = 'markdown' }
        elsif $fileName.match(/ .* \. org $ /) { $fileType = 'org-mode' }
        else {
            die "Unknown file type.";
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
                    .subst: %fileTypeToSearchSub{$fileType}, -> $s { %fileTypeToReplaceSub{$fileType}($sandbox, $s, :$rakuOutputPrompt, :$rakuErrorPrompt) }, :g;
}