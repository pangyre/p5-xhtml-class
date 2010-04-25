use warnings;
use strict;
use Test::More;
use Test::Exception;
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Class;
use Encode;
use utf8;

# What happens with an empty string document?

{
    my $before = <<"BEFORE";
¶aragraph øne¡

¶aragraph †wo…
BEFORE

    my $after = encode("UTF8", <<"AFTER");
<p>¶aragraph øne¡</p>

<p>¶aragraph †wo…</p>
AFTER

    chomp $after;

    cmp_ok($before, "ne", $after,
           "Sanity check: before and after differ");

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new(...)" );

#    diag($xc->as_string);
#    diag($before);
#    diag(chr(8230));

# XHTML::Class::_trim

    is(XHTML::Class::_trim($xc->as_string),
       XHTML::Class::_trim($before),
       "Original content matches stringified object");

exit;

    ok( my $enparaed = $xc->enpara(),
        "Enpara'ing the content" );

    diag( XHTML::Class::_trim($xc->as_string) ) if $ENV{TEST_VERBOSE};

    is(XHTML::Class::_trim($xc->as_string),
       XHTML::Class::_trim($after),
       "Basic test of enpara OK");

}

done_testing();

__END__

my $xc = XHTML::Class->new($before);
print $xc->encoding, $/;
print $xc->enpara, $/;
print $after, $/;
chomp $after;
print $xc eq $after ? "YEAH\n" : ":(\n";
