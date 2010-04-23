#!perl -T
use warnings;
use strict;
use Test::More;
use XHTML::Class qw( xu );

ok( my $xhtml = xu("OH HAI"),
    "New simple string based xu" );

is( $xhtml, "OH HAI",
    "Overloads as same" );

is( $xhtml->enpara->as_string, "<p>OH HAI</p>",
    "Enparas" );

done_testing();
