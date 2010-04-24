#!perl -T
use warnings;
use strict;
use Test::More;
use Test::Exception;
use XHTML::Class;

can_ok("XHTML::Class", "xc");

dies_ok( sub { my $xhtml = xc() },
         "Empty xc dies" );

dies_ok( sub { my $xhtml = xc({ sourze => "some string" }) },
         "Bad key to xc dies" );

done_testing();
