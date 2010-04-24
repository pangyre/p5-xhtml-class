#!perl -T
use warnings;
use strict;
use Test::More;
use XHTML::Class qw( xc );

ok( my $xhtml = xc("OH HAI"),
    "New simple string based xc" );

is( $xhtml->enpara->as_string, "<p>OH HAI</p>",
    "Enparas fine" );

is( xc("OH HAI")->enpara, "<p>OH HAI</p>",
    "Inline works the same" );

done_testing();
