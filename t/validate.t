#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Class;

my $basic_html = "$FindBin::Bin/files/basic.html";
ok( my $xc = XHTML::Class->new($basic_html),
    "XHTML::Class->new(basic.html)" );

ok( $xc->is_valid(),
    "$basic_html is_valid" );

lives_ok( sub { $xc->validate() },
          "$basic_html validates" );

