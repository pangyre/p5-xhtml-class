use warnings;
use strict;
use Test::More;
use XHTML::Class;
# use Encode;
use utf8;

{
    my $before = <<"BEFORE";
<p>¶aragraph øne¡</p>

<p>¶aragraph †wo…</p>
BEFORE

    my $after = <<"AFTER";
  <p>¶aragraph øne¡</p>   
             <p>¶aragraph †wo…</p> 
           
AFTER

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new(...)" );

    ok( my $xc2 = XHTML::Class->new($after),
        "XHTML::Class->new(...)" );

    ok( $xc->same_same($xc2),
        "Same same" );

    isnt( $xc->doc->serialize(0), $xc2->doc->serialize(0),
        "And as XML::LibXML fails" );
}

done_testing();

__END__
