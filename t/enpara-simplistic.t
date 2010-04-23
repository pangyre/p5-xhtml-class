#!perl -T
use warnings;
use strict;
use Test::More;
use XHTML::Class qw( xu );

ok( my $xhtml = xu("OH HAI"),
    "New simple string based xu" );

is( $xhtml->enpara->as_string, "<p>OH HAI</p>",
    "Enparas fine" );

is( xu("OH HAI")->enpara, "<p>OH HAI</p>",
    "Inline works the same" );

done_testing();
