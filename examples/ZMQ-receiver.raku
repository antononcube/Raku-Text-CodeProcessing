#!/usr/bin/env perl6

=begin para
This file shows how to connect to a "remote kernel" process that can be accessed through ZMQ
from, say, Mathematica or RStudio notebooks.

The code below is an adaptation of one of the introductory codes from the ZMQ guide.
See L<"ØMQ - The Guide", "Chapter 1, Basics"|https://zguide.zeromq.org/docs/chapter1/>.
=end para

=begin para
In order to experiment with this program run the following code in Mathematica.
=end para

=begin code
socket = SocketConnect["tcp://localhost:5555", "ZMQ_REP"]

While[True,
 message = SocketReadMessage[socket];
 message2 = ByteArrayToString[message];
 Print["[woflramscirpt] got request:", message2];
 res = ToExpression[message2];
 Print["[woflramscirpt] wvaluated:", res];

 BinaryWrite[socket, StringToByteArray[ToString[res], "UTF-8"]]
]
=end code

=begin para
Alternatively, launch C<woflramscirpt> with the code above given as code argument.
=end para

use v6;

#| Makes WL's ZeroMQ infinite loop program.
sub MakeWLCode( Str :$url = 'tcp://127.0.0.1', Str :$port = '5555', Str :$prepCode = '', Bool :$proclaim = False) {

    my Str $resCode =
    $prepCode ~
"socket = SocketConnect[\"$url:$port\", \"ZMQ_REP\"]

While[True,
 message = SocketReadMessage[socket];
 message2 = ByteArrayToString[message];
 Print[\"[woflramscirpt] got request:\", message2];
 res = ToExpression[message2];
 Print[\"[woflramscirpt] evaluated:\", res];

 BinaryWrite[socket, StringToByteArray[ToString[res], \"UTF-8\"]]
]";

    if !$proclaim {
        $resCode = $resCode.subst( / ^^ \h* 'Print' .*? $$ /, ''):g
    }

    $resCode
};

use Net::ZMQ4;
use Net::ZMQ4::Constants;

#| Main program.
sub MAIN(Str :$url = 'tcp://127.0.0.1', Str :$port = '5555') {

    # Prep code when experimenting with DSL translations by QAS.
    # my Str $prepCode = 'Import["https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/Misc/ComputationalSpecCompletion.m"];';

    # Launch wolframscript with ZMQ socket
    my $proc = Proc::Async.new: 'wolframscript','-code', MakeWLCode(:$url, :$port):!proclaim;
    $proc.start;

    # Socket to talk to clients
    my Net::ZMQ4::Context $context .= new;
    my Net::ZMQ4::Socket $reciever .= new($context, ZMQ_REQ);
    $reciever.bind("$url:$port");

    # Evaluate symbolic expressions.
    for ^4 -> $i {
        my $command = "InputForm[Expand[(a+x)^$i]]";
        $reciever.send($command);
        say "Sent: $command";
        my $message = $reciever.receive();
        say "Received : { $message.data-str }";
    }

    # Evaluate complicate DSL expressions.
    # Make sure the $prepCode above (with Import) is uncommented.
    #`[
    say "=" x 60;
    say 'Evaluate symbolic expressions';
    say "-" x 60;
    my @compSpecs = (
    "Do quantile regression with 12 knots and probabilities 0.1, 0.7 and 0.9 over the dataset finData. Use a datelist plot.",
    "Extract 20 topics from the text corpus aAbstracts using the method NNMF. Show statistical thesaurus with the words neural, function, and notebook.",
    "Make a classifier with dsTitanic data and show the measurements Accuracy and Precision and ROC functions PPV and TPR using the method DecisionTree",
    "Generate a random dataset with 4 columns and 10 rows using the column names generator RandomPetName with max number of values 20. Give the result in long form",
    "Make a recommender with dsTitanic and give top 20 recommendations for the profile male and 1st"
    );
    for @compSpecs -> $spec {
        my $command = 'ComputationalSpecCompletion @ "' ~ $spec ~ '"';
        $reciever.send($command);
        say "-" x 30;
        say "Sent: $command";
        my $message = $reciever.receive();
        say "Received : { $message.data-str }";
    }
    ]

    $proc.kill;
    $proc.kill: SIGKILL
}