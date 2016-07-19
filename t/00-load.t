#!perl -T
# should have used or not !perl -T?
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tk::Knob' ) || print "Bail out!\n";
}

diag( "Testing Knob $Tk::Knob::VERSION, Perl $], $^X" );
