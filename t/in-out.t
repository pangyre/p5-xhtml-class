#!perl -T
use warnings;
use strict;
use Test::More;
use XHTML::Class;

ok( my $xhtml = XHTML::Class->new("OH HAI"),
    "New simple string based xu" );

is( $xhtml, "OH HAI",
    "Overloads as same" );

is( $xhtml->as_string, "OH HAI",
    "Stringifies as same" );

isnt( $xhtml->as_xhtml, "OH HAI",
      "Fails as XHTML" );

# Behavior here is ... uncertainly defined.
#isnt( $xhtml->as_fragment, "OH HAI",
#      "Fails as fragment" );

# This might be WRONG... have to think about it.
is( $xhtml->as_fragment, "OH HAI",
    "Fragment as same" );

done_testing();
