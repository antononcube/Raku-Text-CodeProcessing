#!/usr/bin/env perl6

# The initial version of the code was taken from : https://stackoverflow.com/a/57128623

use v6.d;
use Text::CodeProcessing::REPLSandbox;

unit module Text::CodeProcessing;

##===========================================================
## Code chunk known languages
##===========================================================

#| Known code chunk languages.
our @codeChuckLangs = <perl6 raku>;
#= This variable can be overwritten by other packages

#| Modules for know code chunk languages.
our %codeChunkLangModule;
#= One language one module.

#| Initialization for know code chunk languages.
our %codeChunkLangCaller;

#| Initialization for know code chunk languages.
our %codeChunkLangInit;

##===========================================================
## Code chunk parameters with their default values
##===========================================================
my %defaultChunkParams =
        :echo,
        errorPrompt => '#ERROR: ',
        evaluate => 'TRUE',
        lang => '',
        name => '',
        outputLang => '',
        outputPrompt => '# ',
        outputResults => 'markup';


##===========================================================
## Code chunk parameter extraction
##===========================================================

#| Extract parameters from Match object
sub CodeChunkParametersExtraction( Str $list-of-params, $/, %defaults --> Hash) {

    my $name = $<name> ?? $<name>.Str !! '';
    my $lang = $<lang> ?? $<lang>.Str !! '';
    my $echo = True;
    my $outputResults = 'markup';
    my $outputLang = '';
    my $evaluate = 'TRUE';
    my $outputPrompt = %defaults<outputPrompt> // "# OUTPUT: ";
    my $errorPrompt = %defaults<errorPrompt> // "# ERROR: ";
    my %extra;

    # If a list of parameters is specified extract values
    if $<params>{$list-of-params} {
        for $<params>{$list-of-params}.values -> $pair {

            if $pair<param>.Str (elem) <echo> {

                $echo = $pair<value>.Str.lc ∈ <false no f> ?? False !! True;

            } elsif $pair<param>.Str (elem) <eval evaluate> {

                $evaluate = $pair<value>.Str;

            } elsif $pair<param>.Str eq 'outputLang' || $pair<param>.Str ~~ / output.lang / {

                $outputLang = $pair<value>.Str;
                if $outputLang eq 'NONE' || ! $outputLang.trim {  $outputLang = ''; }

            } elsif $pair<param>.Str eq 'outputPrompt' || $pair<param>.Str ~~ / output.prompt / {

                $outputPrompt = $pair<value>.Str;

                $outputPrompt =
                        do if $outputPrompt eq 'NONE' { '' }
                        elsif $outputPrompt (elem) <AUTO AUTOMATIC GLOBAL Whatever> { $outputPrompt }
                        elsif $outputPrompt eq 'DEFAULT' { '# ' }
                        else { $outputPrompt }

            } elsif $pair<param>.Str eq 'errorPrompt' || $pair<param>.Str ~~ / error.prompt / {

                $errorPrompt = $pair<value>.Str;

                $errorPrompt =
                        do if $errorPrompt eq 'NONE' { '' }
                        elsif $errorPrompt (elem) <AUTO AUTOMATIC GLOBAL Whatever> { $errorPrompt }
                        elsif $errorPrompt eq 'DEFAULT' { '# ERR: ' }
                        else { $errorPrompt }

            } elsif $pair<param>.Str eq 'results' {

                $outputResults = $pair<value>.Str;
                if $outputResults (elem) <AUTO AUTOMATIC Whatever> || ! $outputResults.trim { $outputResults = 'markup'; }
                if $outputResults eq 'asis' { $outputPrompt = ''; }

            } else {
                %extra{$pair<param>} = $pair<value>;
            }
        }
    }

    return Hash( %defaults , %( :$echo, :$evaluate, :$name, :$lang, :$outputLang, :$outputPrompt, :$errorPrompt, :$outputResults ), %extra);
}


##===========================================================
## Markdown functions
##===========================================================

#| Markdown code chunk ticks
constant $mdTicks = '```';

#| Markdown pair assignment
my regex md-assign-pair { $<param>=([<.alpha> | '.' | '_' | '-']+) \h* '=' \h* $<value>=(<-[{}\s]>* | '{' ~ '}' <-[{}]>* ) }

#| Markdown list of assignments
my regex md-list-of-params { <md-assign-pair>+ % [ \h* ',' \h* ] }

#| Markdown code chunk search regex
my regex MarkdownSearch {
    $<header>=(
    $mdTicks '{'? \h* $<lang>=(@codeChuckLangs)
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
                       outputPrompt => $evalOutputPrompt.lc ∈ <auto whatever> ?? '# ' !! $evalOutputPrompt,
                       errorPrompt => $evalErrorPrompt.lc ∈ <auto whatever> ?? '#ERROR: ' !! $evalErrorPrompt,
                       format => 'JSON' ) );

    my $outputLang = %params<outputLang> // '';

    # Construct the replacement string
    my $res = CodeChunkEvaluate($sandbox, $<code>, %params<outputPrompt>, %params<errorPrompt>,
            lang => %params<lang>,
            :$promptPerLine,
            |%params.grep({ $_.key ∉ %defaultChunkParams.keys }).Hash);

    my Bool $evalCode = %params<evaluate>.lc (elem) <true t yes>;
    my $origChunk = %params<echo> ?? $<header> ~ $<code> ~ $mdTicks !! '';
    return do given %params<outputResults> {
        when 'asis' {
            $origChunk ~ ($evalCode ?? "\n" ~ $res !! '');
        }

        when 'hide' {
            $origChunk;
        }

        default {
            $origChunk ~
                    ($evalCode
                        ?? "\n" ~ $mdTicks ~ $outputLang ~ "\n" ~ $res ~ $mdTicks
                        !! '');
        }
    }
}


##===========================================================
## Org-mode functions
##===========================================================

#| Org-mode code block opening
constant $orgBeginSrc = '#+BEGIN_SRC';

#| Org-mode code block closing
constant $orgEndSrc = '#+END_SRC';

#| Org-mode pair assignment
my regex org-assign-pair { ':' $<param>=([<.alpha> | '.' | '_' | '-']+) \h+ $<value>=(\S*) | ':' $<param>=(<.alpha>+) }

#| Org-mode list of assignments
my regex org-list-of-params { <org-assign-pair>+ % [ \h+ ] }

#| Org-mode code chunk search regex
my regex OrgModeSearch {
    $<header>=( $orgBeginSrc \h* $<lang>=(@codeChuckLangs)
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
                       outputPrompt => $evalOutputPrompt.lc ∈ <auto whatever> ?? ': ' !! $evalOutputPrompt,
                       errorPrompt => $evalErrorPrompt.lc ∈ <auto whatever> ?? ':ERROR: ' !! $evalErrorPrompt,
                       format => 'JSON' ) );

    # Construct the replacement string
    my $res = CodeChunkEvaluate(
            $sandbox, $<code>, %params<outputPrompt>, %params<errorPrompt>,
            lang => %params<lang>,
            :$promptPerLine,
            |%params.grep({ $_.key ∉ %defaultChunkParams.keys }).Hash);

    my Bool $evalCode = %params<evaluate>.lc (elem) <true t yes>;
    my $origChunk = %params<echo> ?? $<header> ~ $<code> ~ $orgEndSrc !! '';
    return do given %params<outputResults> {
        when 'asis' {
            $origChunk ~
                    ($evalCode ?? "\n" ~ $res !! '');
        }

        when 'hide' {
            $origChunk;
        }

        default {
            $origChunk ~
                    ($evalCode ?? "\n" ~ "#+RESULTS:" ~ "\n" ~ $res !! "\n");
        }
    }
}


##===========================================================
## Pod6 functions
##===========================================================

#| Pod6 code block opening
constant $podBeginSrc = '=begin code';

#| Pod6 code block opening
constant $podEndSrc = '=end code';

#| Pod6 pair assignment
my regex pod-assign-pair { ':' $<param>=([<.alpha> | '.' | '_' | '-']+) '<' $<value>=(\S*) '>' | ':' $<param>=(<.alpha>+) }

#| Pod6 list of assignments
my regex pod-list-of-params { <pod-assign-pair>+ % [ \h+ ] }

#| Pod6 code chunk search regex
my regex Pod6Search {
    $<header>=( $podBeginSrc [ \h+ ':lang<' @codeChuckLangs '>' ]?
    [ \h+ $<params>=(<pod-list-of-params>) ]? \h* \v )
    $<code>=[<!before $podEndSrc> .]*
    $podEndSrc
}

#| Pod6 replace sub
sub Pod6Replace ($sandbox, $/, Str :$evalOutputPrompt = '# ', Str :$evalErrorPrompt = '#ERROR: ', Bool :$promptPerLine = True) {

    # Determine the code chunk parameters
    my %params =
            CodeChunkParametersExtraction( 'pod-list-of-params', $<header>,
                    %( lang => 'raku',
                       evaluate => 'TRUE',
                       outputPrompt => $evalOutputPrompt.lc ∈ <auto whatever> ?? '# ' !! $evalOutputPrompt,
                       errorPrompt => $evalErrorPrompt.lc ∈ <auto whatever> ?? '#ERROR: ' !! $evalErrorPrompt,
                       format => 'JSON' ) );

    my $outputLang = %params<outputLang> // '';
    if $outputLang { $outputLang = ' :lang<' ~ $outputLang ~ '>'; }

    my $res = CodeChunkEvaluate(
            $sandbox, $<code>, %params<outputPrompt>, %params<errorPrompt>,
            lang => %params<lang>,
            :$promptPerLine,
            |%params.grep({ $_.key ∉ %defaultChunkParams.keys }).Hash);

    my Bool $evalCode = %params<evaluate>.lc (elem) <true t yes>;
    my $origChunk = %params<echo> ?? $<header> ~ $<code> ~ $podEndSrc !! '';
    return do given %params<outputResults> {
        when 'asis' {
            $origChunk ~
                    "\n" ~
                    $res
        }

        when 'hide' {
            $origChunk;
        }

        default {
            $origChunk ~
                    "\n" ~
                    "=begin output" ~ $outputLang ~ "\n" ~
                    $res ~
                    "=end output";
        }
    }
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
                       *%params) is export {

    # If DSL evaluation is specified change the code accordingly
    my $code-to-eval = do given $lang {

        when %codeChunkLangCaller{$_}:exists {
            my $ps = %params.grep({ $_.key ∉ %defaultChunkParams.keys }).map({ "{$_.key} => {(+$_.value).defined ?? $_.value !! "'{$_.value}'"}" }).join(', ');
            %codeChunkLangCaller{$_}.($code.Str, $ps)
        }

        default { $code.Str }
    }

    if %codeChunkLangModule{$lang}:exists && !(%codeChunkLangInit{$lang} // False) {

        # Check if the required module(s) are installed
        if ! is-installed(%codeChunkLangModule{$lang}) {
            die "The module {%codeChunkLangModule{$lang}} has to be installed in order to use $lang code chunk evaluation.";
        }

        # Add package loading
        $code-to-eval = "use {%codeChunkLangModule{$lang}};" ~ "\n" ~ $code-to-eval;

        # Mark the DSL initialization
        %codeChunkLangInit{$lang} = True;
    }

    ## Redirecting stdout to a custom $out
    my $out;

    my $*OUT = $*OUT but role {
        method print (*@args) {
            $out ~= @args
        }
    }

    ## Redirecting stdout to a custom $err
    my $err;

    my $*ERR = $*ERR but role {
        method print (*@args) {
            $err ~= @args
        }
    }

    # REPL sandbox execution
    $sandbox.execution-count++;
    my $p = $sandbox.eval($code-to-eval, :store($sandbox.execution-count));

    ## Result with prompts
    ($p.exception ?? add-prompt($evalErrorPrompt, $p.exception.Str.trim, :$promptPerLine) ~ "\n" !! '') ~
            ($err ?? add-prompt($evalErrorPrompt, $err.Str.trim, :$promptPerLine) ~ "\n" !! '') ~
            add-prompt($evalOutputPrompt, ($out // $p.output).trim, :$promptPerLine) ~
            "\n"
}


##===========================================================
## StringCodeChunksEvaluation
##===========================================================

#| Evaluates code chunks in a string.
sub StringCodeChunksEvaluation(Str:D $input,
                               Str:D $docType,
                               :$evalOutputPrompt is copy = Whatever,
                               :$evalErrorPrompt is copy = Whatever,
                               Bool :$promptPerLine = True) is export {

    die "The second argument is expected to be one of {%fileTypeToReplaceSub.keys.join(', ')}."
    unless $docType (elem) %fileTypeToReplaceSub.keys;

    if $evalOutputPrompt.isa(Whatever) { $evalOutputPrompt = 'Whatever' }
    die "The argument evalOutputPrompt is expected to be a string or Whatever."
    unless $evalOutputPrompt ~~ Str;

    if $evalErrorPrompt.isa(Whatever) { $evalErrorPrompt = 'Whatever' }
    die "The argument evalErrorPrompt is expected to be a string or Whatever."
    unless $evalErrorPrompt ~~ Str;

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
                             :$outputFileName = Whatever,
                             :$evalOutputPrompt is copy = Whatever,
                             :$evalErrorPrompt is copy = Whatever,
                             Bool :$noteOutputFileName = False,
                             Bool :$promptPerLine = True,
                             Bool :$tangle = False) {

    ## Determine the output file name and type
    my Str $fileNameNew;
    my Str $fileType;
    my Str $autoSuffix = $tangle ?? '_tangled' !! '_woven';

    if $outputFileName.isa(Str) {
        $fileNameNew = $outputFileName
    } elsif $outputFileName.isa(Whatever) {
        ## If the input file name has extension that is one of <md MD Rmd org pod6>
        ## then insert "_weaved" before the extension.
        if $fileName.match(/ :i .* \. [md | Rmd | qmd | org | pod6] $ /) {
            $fileNameNew = $fileName.subst(/ $<name> = (.*) '.' $<ext> = (md | MD | Rmd | qmd | org | pod6) $ /, -> $/ { $<name> ~ $autoSuffix ~ '.' ~ $<ext> });
        } else {
            $fileNameNew = $fileName ~ $autoSuffix;
        }
    } else {
        die 'The argument $outputFileName is expected to be string or Whatever.';
    }

    if $fileName.match(/ :i .* \. [md | Rmd | qmd] $ /) { $fileType = 'markdown' }
    elsif $fileName.match(/ :i .* \. org $ /) { $fileType = 'org-mode' }
    elsif $fileName.match(/ :i .* \. pod6 $ /) { $fileType = 'pod6' }
    else {
        die "Unknown file type (extension). The file type (extension) is expectecd to be one of {<md Rmd qmd org pod6>}.";
    }

    if $noteOutputFileName {
        note "Output file is $fileNameNew" unless $outputFileName;
    }

    ## Process output prompt
    if $evalOutputPrompt.isa(Whatever) { $evalOutputPrompt = 'Whatever' }
    die "The argument evalOutputPrompt is expected to be a string or Whatever."
    unless $evalOutputPrompt ~~ Str;

    ## Process error prompt
    if $evalErrorPrompt.isa(Whatever) { $evalErrorPrompt = 'Whatever' }
    die "The argument evalErrorPrompt is expected to be a string or Whatever."
    unless $evalErrorPrompt ~~ Str;

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
                             :$outputFileName = Whatever,
                             :$evalOutputPrompt = 'AUTO',
                             :$evalErrorPrompt = 'AUTO',
                             Bool :$noteOutputFileName = True,
                             Bool :$promptPerLine = True) is export {

    FileCodeChunksProcessing( $fileName, :$outputFileName, :$evalOutputPrompt, :$evalErrorPrompt, :$noteOutputFileName, :$promptPerLine, :!tangle)
}


##===========================================================
## FileCodeChunksExtraction
##===========================================================

#| Extracts code from code chunks in a file.
sub FileCodeChunksExtraction(Str $fileName,
                             :$outputFileName = Whatever,
                             Bool :$noteOutputFileName = True) is export {

    FileCodeChunksProcessing( $fileName, :$outputFileName, :$noteOutputFileName, :tangle)
}


##===========================================================
## Register code chunk lang
##===========================================================

#| Register code chunk language.
sub register-lang(Str :$lang!, Str :$module!, :&caller!) is export {

    @codeChuckLangs.append($lang);

    if $module { %codeChunkLangModule{$lang} = $module; }

    %codeChunkLangCaller{$lang} = &caller;
}


##===========================================================
## Plug-in definition
##===========================================================

# Shell
register-lang(
        lang => 'shell',
        module => '',
        caller => -> $code, $params {
            'my $pCoDeXe832xereSWEiie3 = Q (' ~ $code.Str ~ '); my $proc = Proc.new(:out); $proc.shell($pCoDeXe832xereSWEiie3); my $captured-output = $proc.out.slurp: :close; $captured-output;'
        } );

# DSL
register-lang(
        lang => 'raku-dsl',
        module => 'DSL::Shared::Utilities::ComprehensiveTranslation',
        caller => -> $code, $params { 'ToDSLCode(Q｢｢｢｢' ~ $code.Str ~ '｣｣｣｣' ~ ($params ?? ", $params" !! '') ~ ')' } );

# OpenAI
register-lang(
        lang => 'openai',
        module => 'WWW::OpenAI',
        caller => -> $code, $params {'openai-completion(Q｢｢｢｢' ~ $code.Str ~ '｣｣｣｣' ~ ($params ?? ", $params" !! '') ~ ')' });

# PaLM
register-lang(
        lang => 'palm',
        module => 'WWW::PaLM',
        caller => -> $code, $params {'palm-generate-text(Q｢｢｢｢' ~ $code.Str~ '｣｣｣｣' ~ ($params ?? ", $params" !! '') ~ ')' });
