#!perl -T
use warnings;
use strict;
use Test::More;
use Test::Exception;
use XHTML::Class;

dies_ok( sub { my $xhtml = xu() },
         "Empty xu dies" );

dies_ok( sub { my $xhtml = xu({ sourze => "some string" }) },
         "Bad key to xu dies" );

done_testing();
