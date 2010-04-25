#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Class;

ok( my $xc = XHTML::Class->new(\"something"),
    "XHTML::Class->new " );

dies_ok( sub { $xc->translate_tags('whatever') },
         "Not implemented" );
