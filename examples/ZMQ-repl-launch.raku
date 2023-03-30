#!/usr/bin/env perl6

=begin para
This file shows how create simple "remote kernel" process that can be accessed through ZMQ
from, say, Mathematica or RStudio notebooks.

Since the code is small it can be included inside Mathematica or R packages.
See the Mathematica package
L<C<RakuMode>|https://github.com/antononcube/ConversationalAgents/blob/master/Packages/WL/RakuMode.m>.

The code below is an adaptation of one of the introductory codes from the ZMQ guide.
See L<"ØMQ - The Guide", "Chapter 1, Basics"|https://zguide.zeromq.org/docs/chapter1/>.
=end para

use v6.d;

use Net::ZMQ4;
use Net::ZMQ4::Constants;
use Text::CodeProcessing::REPLSandbox;
use Text::CodeProcessing;

sub MAIN(Str :$url = 'tcp://*', Str :$port = '5555', Str :$rakuOutputPrompt = '', Str :$rakuErrorPrompt = '#ERROR: ') {

    # Socket to talk to clients
    my Net::ZMQ4::Context $context .= new;
    my Net::ZMQ4::Socket $responder .= new($context, ZMQ_REP);
    $responder.bind("$url:$port");

    ## Create a sandbox
    my $sandbox = Text::CodeProcessing::REPLSandbox.new();

    while (1) {
        my $message = $responder.receive();
        say "Received {DateTime.now} : { $message.data-str }";
        my $res = CodeChunkEvaluate($sandbox, $message.data-str, $rakuOutputPrompt, $rakuErrorPrompt);
        $message.close;
        $responder.send($res);
    }
}