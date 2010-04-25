#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Class;

SKIP: {
    skip "Just not done yet", 2;

    ok( my $xc = XHTML::Class->new,
        "XHTML::Class->new " );

    dies_ok( sub { $xc->inline_stylesheets('whatever') },
             "Not implemented" );
}
