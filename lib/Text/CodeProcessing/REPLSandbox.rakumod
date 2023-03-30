
# The REPL sandbox code was taken from Jupyter::Kernel::Sandbox :
# https://github.com/bduggan/p6-jupyter-kernel/blob/master/lib/Jupyter/Kernel/Sandbox.rakumod

use v6.d;

use nqp;

#| Mime type sub (not used now)
sub mime-type($str) is export {
    return do given $str {
        when /:i ^ '<svg' / {
            'image/svg+xml';
        }
        default { 'text/plain' }
    }
}

#| Result class to keep outputs, exception, mime-type, and expression completeness flag
my class Result {
    has Str $.output;
    has $.output-raw is default(Nil);
    has $.exception;
    has Bool $.incomplete;
    method output-mime-type {
        return mime-type($.output // '');
    }
}

#| REPL sandbox class
class Text::CodeProcessing::REPLSandbox is export {
    has $.save_ctx;
    has $.compiler;
    has $.repl;
    has $.execution-count is rw = 0;

    #| The creation of a sandbox object is tweaked
    #| to have REPL compiler initialized and
    #| have initialization code for storing outputs executed in
    #| that REPL compiler.
    method TWEAK () {
        $!compiler := nqp::getcomp("Raku") || nqp::getcomp('perl6');
        $!repl = REPL.new($!compiler, {});

        #| The following REPL initialization code:
        #| - Sets a list/array for all output: C<$Out>
        #| - Defines a function to to obtain the list of saved outputs: C<Out>
        #| - Defines a sigill-less variable, C<\_>, to store and retrieve the last result
        #|    - See the (C<if $store {...}}>) code in the method C<eval>
        self.eval(q:to/INIT/);
            my $Out = [];
            sub Out { $Out };
            my \_ = do {
                state $last;
                Proxy.new( FETCH => method () { $last },
                           STORE => method ($x) { $last = $x } );
            }
        INIT

    }

    #| The main REPL sandbox method
    method eval(Str $code, Bool :$no-persist, Int :$store) {
        #| Context to be saved
        my $*CTXSAVE = $!repl;

        #| Variable for $!save_ctx
        my $*MAIN_CTX;

        my $exception;
        my $eval-code = $code;

        #| If the named argument C<$store> is larger than 0
        #| then the code is wrapped in appropriate storage calls.
        if $store {
            $eval-code = qq:to/DONE/
                my \\_$store = \$(
                    $code
                );
                \$Out[$store] := _$store;
                _ = _$store;
                DONE

             }

        #| Get the evaluation result
        my $output is default(Nil);
        my $gist;
        try {
            $output = $!repl.repl-eval(
                    $eval-code,
                    $exception,
                    :outer_ctx($!save_ctx),
                    :interactive(1)
                    );

            $gist = $output.gist;
            CATCH {
                default {
                    $exception = $_;
                }
            }
        }

        #| If the output is "non-result" make it Nil
        given $output {
            $_ = Nil if .?__hide;
            $_ = Nil if $_ ~~ List and .elems and .[*- 1].?__hide;
            $_ = Nil if $_ === Any;
        }

        #| If the gist is "non-result" make it Nil
        if $gist === Any or $gist === Nil { $gist = "Nil"}

        #| REPL context is saved/stored
        if $*MAIN_CTX and !$no-persist {
            $!save_ctx := $*MAIN_CTX;
        }

        #| If there is an exception modify the output
        #        with $exception {
        #            $output = ~$_;
        #            $gist = $output;
        #        }

        #| Set the flag for non-completion
        my $incomplete = so $!repl.input-incomplete($output);

        #| Make and initialize the result object
        my $result = Result.new:
                :output($gist),
                :output-raw($output),
                :$exception,
                :$incomplete;

        #| Result
        $result;
    }
}
