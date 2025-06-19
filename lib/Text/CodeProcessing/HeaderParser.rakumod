use v6.d;

# YAML Rmd notebooks header parser and interpreter.

grammar Text::CodeProcessing::Header {
    regex TOP { ^ \v* <code-fence> \v <header> \v+ <code-fence> .*}
    token code-fence { ^^ '-' ** 3..*}
    regex header { [ <nested> | <pair> ]* % \v }
    regex pair { <key> \h* ':' \h* <value> }
    token key { <-[:\s]>+ }
    regex value { <number> | <boolean> | <string> }
    token string { \w \V+ | '"' <-["\v]>+ '"' | '\'' <-['\v]>+ '\'' }
    token boolean {:i true | false}
    regex number { \d+ [ '.' \d+ ]? [ <[eE]> [ '+' | '-' ]? \d+ ]? }
    regex nested { <key> \h* ':' \h* \v [ <indent-pair>* % \v ] }
    token indent { \h+ }
    regex indent-pair { <indent> <pair> }
}

class Text::CodeProcessing::HeaderActions {
    method TOP($/) { make $<header>.made }
    method header($/) { make [|$<pair>».made, |$<nested>».made].Hash }
    method pair($/) {
        my $key = $<key>.Str;
        my $value = $<value>.made;
        make Pair.new($key, $value);
    }
    method indent-pair($/) {
        make $<pair>.made;
    }
    method string($/) { make $/.Str.subst(/ ^ '"' | '"' $/, :g).subst(/ ^ '\'' | '\'' $/, :g) }
    method boolean($/) { make $/.Str.lc eq 'true' ?? True !! False }
    method number($/) { make $/.Str.Numeric }
    method value($/) { make $/.values[0].made }
    method nested($/) { make $<key>.Str => $/<indent-pair>».made.Hash }
}
