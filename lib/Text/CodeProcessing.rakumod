#!/usr/bin/env perl6

# The initial version of the code was taken from : https://stackoverflow.com/a/57128623

use v6;
use Text::CodeProcessing::REPLSandbox;

##===========================================================
## Markdown functions
##===========================================================

#| Markdown code chunk ticks
constant $mdTicks = '```';

#| Markdown code chunk search regex
my regex MarkdownSearch {
    $mdTicks '{' \h* $<lang>=('perl6' | 'raku') [\h+ ('evaluate' | 'eval') \h* '=' \h* $<evaluate>=(TRUE | T | FALSE | F) | \h*] '}'
    $<code>=[<!before $mdTicks> .]*
    $mdTicks
}

#| Markdown replace sub
sub MarkdownReplace ($sandbox, $/, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ') {
    $mdTicks ~ $<lang> ~ $<code> ~ $mdTicks ~
            (!$<evaluate> || $<evaluate>.Str (elem) <TRUE T>
                    ?? "\n" ~ $mdTicks ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, $evalOutputPrompt, $evalErrorPrompt) ~ $mdTicks
                    !! '');
}


##===========================================================
## Org-mode functions
##===========================================================

constant $orgBeginSrc = '#+BEGIN_SRC';
constant $orgEndSrc = '#+END_SRC';

#| Org-mode code chunk search regex
my regex OrgModeSearch {
    $orgBeginSrc \h* $<lang>=('perl6' | 'raku') $<ccrest>=(\V*) \v
    $<code>=[<!before $orgEndSrc> .]*
    $orgEndSrc
}

#| Org-mode replace sub
sub OrgModeReplace ($sandbox, $/, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ') {
    $orgBeginSrc ~ ' ' ~ $<lang> ~ $<ccrest> ~ "\n" ~ $<code> ~ $orgEndSrc ~
            "\n" ~ "#+RESULTS:" ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, ': ', ':ERROR: ');
}


##===========================================================
## Pod6 functions
##===========================================================

constant $podBeginSrc = '=begin code';
constant $podEndSrc = '=end code';

#| Pod6 code chunk search regex
my regex Pod6Search {
    $podBeginSrc \v
    $<code>=[<!before $podEndSrc> .]*
    $podEndSrc
}

#| Pod6 replace sub
sub Pod6Replace ($sandbox, $/, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ') {
    $podBeginSrc ~ "\n" ~ $<code> ~ $podEndSrc ~
            "\n" ~ "=begin output" ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, $evalOutputPrompt, $evalErrorPrompt) ~ "=end output";
}

##===========================================================
## Dictionaries of file-type => sub
##===========================================================

my %fileTypeToSearchSub =
        markdown => &MarkdownSearch,
        org-mode => &OrgModeSearch,
        pod6 => &Pod6Search;

my %fileTypeToReplaceSub =
        markdown => &MarkdownReplace,
        org-mode => &OrgModeReplace,
        pod6 => &Pod6Replace;


##===========================================================
## Evaluation
##===========================================================

#| Evaluation of code chunk
sub CodeChunkEvaluate ($sandbox, $code, $evalOutputPrompt, $evalErrorPrompt) is export {

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
    ($p.exception ?? $evalErrorPrompt ~ $p.exception ~ "\n" !! '') ~ $evalOutputPrompt ~ ($out // $p.output ~ "\n")
}


##===========================================================
## StringCodeChunksEvaluation
##===========================================================

#| The main function
sub StringCodeChunksEvaluation(Str:D $input,
                               Str:D $docType,
                               Str:D :$evalOutputPrompt = '# ',
                               Str:D :$evalErrorPrompt = '#ERROR: ') is export {

    die "The second argument is expected to be one of {%fileTypeToReplaceSub.keys}"
    unless $docType (elem) %fileTypeToReplaceSub.keys;

    ## Create a sandbox
    my $sandbox = Text::CodeProcessing::REPLSandbox.new();

    ## Process code chunks (weave output)
    $input.subst: %fileTypeToSearchSub{$docType}, -> $s { %fileTypeToReplaceSub{$docType}($sandbox, $s,
                                                                                          :$evalOutputPrompt,
                                                                                          :$evalErrorPrompt) }, :g;
}


##===========================================================
## FileCodeChunksEvaluation
##===========================================================

sub FileCodeChunksEvaluation(Str $fileName,
                             Str :$outputFileName,
                             Str :$evalOutputPrompt = '# ',
                             Str :$evalErrorPrompt = '#ERROR: ',
                             Bool :$noteOutputFileName = False) is export {

    ## Determine the output file name and type
    my Str $fileNameNew;
    my Str $fileType;

    with $outputFileName {
        $fileNameNew = $outputFileName
    } else {
        ## If the input file name has extension that is one of <md MD Rmd org pod6>
        ## then insert "_weaved" before the extension.
        if $fileName.match(/ .* \. [md | MD | Rmd | org | pod6] $ /) {
            $fileNameNew = $fileName.subst(/ $<name> = (.*) '.' $<ext> = (md | MD | Rmd | org | pod6) $ /, -> $/ { $<name> ~ '_weaved.' ~ $<ext> });
        } else {
            $fileNameNew = $fileName ~ '_weaved';
        }
    }

    if $fileName.match(/ .* \. [md | MD | Rmd] $ /) { $fileType = 'markdown' }
    elsif $fileName.match(/ .* \. org $ /) { $fileType = 'org-mode' }
    elsif $fileName.match(/ .* \. pod6 $ /) { $fileType = 'pod6' }
    else {
        die "Unknown file type.";
    }

    if $noteOutputFileName {
        note "Output file is $fileNameNew" unless $outputFileName;
    }

    ## Process code chunks (weave output) and spurt in a file
    spurt( $fileNameNew, StringCodeChunksEvaluation(slurp($fileName), $fileType, :$evalOutputPrompt, :$evalErrorPrompt) )
}