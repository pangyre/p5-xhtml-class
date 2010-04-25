use strict;
use warnings;
use Test::More "no_plan";
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
<p>¶aragraph øne¡</p>

<p>¶aragraph †wo…</p>
BEFORE

    my $after = <<"AFTER";
 <p>¶aragraph øne¡</p>   
             <p>¶aragraph †wo…</p> 
   
AFTER

    ok( my $xc = XHTML::Class->new(\$before),
        "XHTML::Class->new(...)" );

    ok( my $xc2 = XHTML::Class->new(\$after),
        "XHTML::Class->new(...)" );

    ok( $xc->same_same($xc2),
        "Same same" );

    isnt( $xc->doc->serialize(0), $xc2->doc->serialize(0),
        "And as XML::LibXML fails" );
}

__END__
