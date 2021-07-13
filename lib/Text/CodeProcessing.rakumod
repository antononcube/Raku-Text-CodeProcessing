#!/usr/bin/env perl6

# The initial version of the code was taken from : https://stackoverflow.com/a/57128623

use v6;
use Text::CodeProcessing::REPLSandbox;

##===========================================================
## Code chunk parameter extraction
##===========================================================

#| Extract parameters from Match object
sub CodeChunkParametersExtraction( Str $list-of-params, $/, %defaults --> Hash) {

    my $name = $<name> ?? $<name>.Str !! '';
    my $lang = $<lang>.Str;
    my $evaluate = 'TRUE';
    my $format = 'JSON';
    my $outputPrompt = %defaults<outputPrompt> // "# OUTPUT: ";
    my $errorPrompt = %defaults<errorPrompt> // "# ERROR: ";

    # If a list of parameters is specified extract values
    if $<params>{$list-of-params} {
        for $<params>{$list-of-params}.values -> $pair {

            if $pair<param>.Str (elem) <eval evaluate> {

                $evaluate = $pair<value>.Str;

            } elsif $pair<param>.Str eq 'format' {

                $format = $pair<value>.Str

            } elsif $pair<param>.Str eq 'outputPrompt' {

                $outputPrompt = $pair<value>.Str;

                $outputPrompt =
                        do if $outputPrompt eq 'NONE' { '' }
                        elsif $outputPrompt (elem) <AUTO AUTOMATIC GLOBAL> { $outputPrompt }
                        elsif $outputPrompt eq 'DEFAULT' { '# ' }
                        else { $outputPrompt }

            } elsif $pair<param>.Str eq 'errorPrompt' {

                $errorPrompt = $pair<value>.Str;

                $errorPrompt =
                        do if $errorPrompt eq 'NONE' { '' }
                        elsif $errorPrompt (elem) <AUTO AUTOMATIC GLOBAL> { $errorPrompt }
                        elsif $errorPrompt eq 'DEFAULT' { '# ERR: ' }
                        else { $errorPrompt }
            }
        }
    }

    Hash( %defaults , %( :$evaluate, :$name, :$lang, :$format, :$outputPrompt, :$errorPrompt ) )
}


##===========================================================
## Markdown functions
##===========================================================

#| Markdown code chunk ticks
constant $mdTicks = '```';

#| Markdown pair assignment
my regex md-assign-pair { $<param>=(<.alpha>+) \h* '=' \h* $<value>=(<-[ \{ \} \s ]>*) }

#| Markdown list of assignments
my regex md-list-of-params { <md-assign-pair>+ % [ \h* ',' \h* ] }

#| Markdown code chunk search regex
my regex MarkdownSearch {
    $<header>=(
    $mdTicks '{'? \h* $<lang>=('perl6' | 'raku' | 'raku-dsl')
    [ \h+ $<name>=(<alpha>+) ]?
    [ \h* ',' \h* $<params>=(<md-list-of-params>) ]? \h* '}'? \h* \v )
    $<code>=[<!before $mdTicks> .]*
    $mdTicks
}

#| Markdown replace sub
sub MarkdownReplace ($sandbox, $/, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ', Bool :$promptPerLine = True) {

    # Determine the code chunk parameters
    my %params =
            CodeChunkParametersExtraction( 'md-list-of-params', $<header>,
                    %( lang => 'raku',
                       evaluate => 'TRUE',
                       outputPrompt => $evalOutputPrompt eq 'AUTO' ?? '# ' !! $evalOutputPrompt,
                       errorPrompt => $evalErrorPrompt eq 'AUTO' ?? '#ERROR: ' !! $evalErrorPrompt,
                       format => 'JSON' ) );

    # Construct the replacement string
    $<header> ~ $<code> ~ $mdTicks ~
            ( %params<evaluate>.lc (elem) <true t yes>
                    ?? "\n" ~ $mdTicks ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, %params<outputPrompt>, %params<errorPrompt>, lang => %params<lang>, format => %params<format>, :$promptPerLine) ~ $mdTicks
                    !! '');
}


##===========================================================
## Org-mode functions
##===========================================================

#| Org-mode code block openning
constant $orgBeginSrc = '#+BEGIN_SRC';

#| Org-mode code block closing
constant $orgEndSrc = '#+END_SRC';

#| Markdown pair assignment
my regex org-assign-pair { ':' $<param>=(<.alpha>+) \h+ $<value>=(\S*) | ':' $<param>=(<.alpha>+) }

#| Markdown list of assignments
my regex org-list-of-params { <org-assign-pair>+ % [ \h+ ] }

#| Org-mode code chunk search regex
my regex OrgModeSearch {
    $<header>=( $orgBeginSrc \h* $<lang>=('perl6' | 'raku' | 'raku-dsl')
    [ \h+ $<params>=(<org-list-of-params>) ]? \h* \v )
    $<code>=[<!before $orgEndSrc> .]*
    $orgEndSrc
}

#| Org-mode replace sub
sub OrgModeReplace ($sandbox, $/, Str :$evalOutputPrompt = ': ', Str :$evalErrorPrompt = ':ERROR: ', Bool :$promptPerLine = True) {

    # Determine the code chunk parameters
    my %params =
            CodeChunkParametersExtraction( 'org-list-of-params', $<header>,
                    %( lang => 'raku',
                       evaluate => 'TRUE',
                       outputPrompt => $evalOutputPrompt eq 'AUTO' ?? ': ' !! $evalOutputPrompt,
                       errorPrompt => $evalErrorPrompt eq 'AUTO' ?? ':ERROR: ' !! $evalErrorPrompt,
                       format => 'JSON' ) );

    # Construct the replacement string
    $<header> ~ $<code> ~ $orgEndSrc ~
            ( %params<evaluate>.lc (elem) <true t yes>
                    ?? "\n" ~ "#+RESULTS:" ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, %params<outputPrompt>, %params<errorPrompt>, lang => %params<lang>, format => %params<format>, :$promptPerLine)
                    !! "\n" );
}


##===========================================================
## Pod6 functions
##===========================================================

constant $podBeginSrc = '=begin code';
constant $podEndSrc = '=end code';

#| Pod6 code chunk search regex
my regex Pod6Search {
    $<header>=( $podBeginSrc \v )
    $<code>=[<!before $podEndSrc> .]*
    $podEndSrc
}

#| Pod6 replace sub
sub Pod6Replace ($sandbox, $/, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ', Bool :$promptPerLine = True) {

    my $outputPrompt = $evalOutputPrompt eq 'AUTO' ?? '# ' !! $evalOutputPrompt;
    my $errorPrompt = $evalErrorPrompt eq 'AUTO' ?? '#ERROR: ' !! $evalErrorPrompt;

    $<header> ~ $<code> ~ $podEndSrc ~
            "\n" ~ "=begin output" ~ "\n" ~ CodeChunkEvaluate($sandbox, $<code>, $outputPrompt, $errorPrompt, :$promptPerLine) ~ "=end output";
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

#| Checks if a module is installed.
sub is-installed(Str $module-name) {
    try {
        require ::($module-name);
        return True;
    }
    False;
}

#| Adds a prompt to multi-line text.
sub add-prompt( Str:D $prompt, Str:D $text, Bool :$promptPerLine = True) {
    $prompt ~ ( $promptPerLine ?? $text.subst( "\n", "\n$prompt", :g) !! $text )
}

#| Evaluates a code chunk in a REPL sandbox.
sub CodeChunkEvaluate ($sandbox, $code, $evalOutputPrompt, $evalErrorPrompt,
                       Str :$lang = 'raku',
                       Bool :$promptPerLine = True,
                       Str :$format = 'JSON' ) is export {

    # State for whether DSL evaluation is initialized or not
    state $dslCodeCallInit = 0;

    # If DSL evaluation is specified change the code accordingly
    my $code-to-eval = $lang eq 'raku-dsl' ?? 'ToDSLCode("' ~ $code.Str.subst('"', '\"', :g) ~ '", format => "' ~ $format ~ '")' !! $code.Str ;

    if $lang eq 'raku-dsl' and not $dslCodeCallInit {

        # Check if the DSL::Shared::Utilities::ComprehensiveTranslation package is installed
        if not is-installed('DSL::Shared::Utilities::ComprehensiveTranslation') {
            die "The module DSL::Shared::Utilities::ComprehensiveTranslation has to be installed in order to use raku-dsl code chunk evaluation.";
        }

        # Add package loading
        $code-to-eval = "use DSL::Shared::Utilities::ComprehensiveTranslation;\n" ~ $code-to-eval;

        # Mark the DSL initialization
        $dslCodeCallInit = 1
    }

    ## Redirecting stdout to a custom $out
    my $out;

    my $*OUT = $*OUT but role {
        method print (*@args) {
            $out ~= @args
        }
    }

    # REPL sandbox execution
    $sandbox.execution-count++;
    my $p = $sandbox.eval($code-to-eval, :store($sandbox.execution-count));

    ## Result with prompts
    ($p.exception ?? add-prompt($evalErrorPrompt, $p.exception.Str.trim, :$promptPerLine) ~ "\n" !! '') ~
            add-prompt($evalOutputPrompt, ($out // $p.output).trim, :$promptPerLine) ~
            "\n"
}


##===========================================================
## StringCodeChunksEvaluation
##===========================================================

#| Evaluates code chunks in a string.
sub StringCodeChunksEvaluation(Str:D $input,
                               Str:D $docType,
                               Str:D :$evalOutputPrompt = 'AUTO',
                               Str:D :$evalErrorPrompt = 'AUTO',
                               Bool :$promptPerLine = True) is export {

    die "The second argument is expected to be one of {%fileTypeToReplaceSub.keys}"
    unless $docType (elem) %fileTypeToReplaceSub.keys;

    ## Create a sandbox
    my $sandbox = Text::CodeProcessing::REPLSandbox.new();

    ## Process code chunks (weave output)
    $input.subst: %fileTypeToSearchSub{$docType}, -> $s { %fileTypeToReplaceSub{$docType}($sandbox, $s,
                                                                                          :$evalOutputPrompt,
                                                                                          :$evalErrorPrompt,
                                                                                          :$promptPerLine) }, :g;
}


##===========================================================
## StringCodeChunksExtraction
##===========================================================

#| Extracts code from code chunks in a string.
sub StringCodeChunksExtraction(Str:D $input,
                               Str:D $docType) is export {

    die "The second argument is expected to be one of {%fileTypeToReplaceSub.keys}"
    unless $docType (elem) %fileTypeToReplaceSub.keys;

    ## Process code chunks (weave output)
    $input.match( %fileTypeToSearchSub{$docType}, :g).map({ trim($_.<code>) }).join("\n")
}


##===========================================================
## FileCodeChunksProcessing
##===========================================================

#| Evaluates code chunks in a file.
sub FileCodeChunksProcessing(Str $fileName,
                             Str :$outputFileName,
                             Str :$evalOutputPrompt = 'AUTO',
                             Str :$evalErrorPrompt = 'AUTO',
                             Bool :$noteOutputFileName = False,
                             Bool :$promptPerLine = True,
                             Bool :$tangle = False) {

    ## Determine the output file name and type
    my Str $fileNameNew;
    my Str $fileType;
    my Str $autoSuffix = $tangle ?? '_tangled' !! '_woven';

    with $outputFileName {
        $fileNameNew = $outputFileName
    } else {
        ## If the input file name has extension that is one of <md MD Rmd org pod6>
        ## then insert "_weaved" before the extension.
        if $fileName.match(/ .* \. [md | MD | Rmd | org | pod6] $ /) {
            $fileNameNew = $fileName.subst(/ $<name> = (.*) '.' $<ext> = (md | MD | Rmd | org | pod6) $ /, -> $/ { $<name> ~ $autoSuffix ~ '.' ~ $<ext> });
        } else {
            $fileNameNew = $fileName ~ $autoSuffix;
        }
    }

    if $fileName.match(/ .* \. [md | MD | Rmd] $ /) { $fileType = 'markdown' }
    elsif $fileName.match(/ .* \. org $ /) { $fileType = 'org-mode' }
    elsif $fileName.match(/ .* \. pod6 $ /) { $fileType = 'pod6' }
    else {
        die "Unknown file type (extension). The file type (extension) is expectecd to be one of {<md MD Rmd org pod6>}.";
    }

    if $noteOutputFileName {
        note "Output file is $fileNameNew" unless $outputFileName;
    }

    ## Process code chunks (weave output) and spurt in a file
    if $tangle {
        spurt( $fileNameNew, StringCodeChunksExtraction(slurp($fileName), $fileType) )
    } else {
        spurt( $fileNameNew, StringCodeChunksEvaluation(slurp($fileName), $fileType, :$evalOutputPrompt, :$evalErrorPrompt, :$promptPerLine) )
    }
}


##===========================================================
## FileCodeChunksEvaluation
##===========================================================

#| Evaluates code chunks in a file.
sub FileCodeChunksEvaluation(Str $fileName,
                             Str :$outputFileName,
                             Str :$evalOutputPrompt = 'AUTO',
                             Str :$evalErrorPrompt = 'AUTO',
                             Bool :$noteOutputFileName = True,
                             Bool :$promptPerLine = True) is export {

    FileCodeChunksProcessing( $fileName, :$outputFileName, :$evalOutputPrompt, :$evalErrorPrompt, :$noteOutputFileName, :$promptPerLine, :!tangle)
}


##===========================================================
## FileCodeChunksExtraction
##===========================================================

#| Extracts code from code chunks in a file.
sub FileCodeChunksExtraction(Str $fileName,
                             Str :$outputFileName,
                             Bool :$noteOutputFileName = True) is export {

    FileCodeChunksProcessing( $fileName, :$outputFileName, :$noteOutputFileName, :tangle)
}