use warnings;
use strict;
use Test::More "no_plan";
use XHTML::Class;
use utf8;

# What happens with an empty string document?

{
    my $before = <<"BEFORE";
<p><a href="/some/uri">¶aragraph øne¡</a></p>

<blockquote><p>¶aragraph <i><b>two</b>...</i></p></blockquote>
BEFORE

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new(...)" );

#    diag( $xc->as_string );

    ok( $xc->strip_tags("a"), "Strip <a/>" );

    unlike( $xc->as_string, qr/<a\s/,
          'No /<a\s/');

    ok( $xc->strip_tags("blockquote p"), "Strip p beneath blockquote" );

    unlike( $xc->as_string, qr/<blockquote>[^<]*<p>/,
          'No /<blockquote><p>/');

    like( $xc->as_string, qr/<p>/,
          'Still have a <p>');

    ok( $xc->strip_tags("i,b"), "Try to strip i,b at the top of fragment" );
    unlike( $xc->as_string, qr/<i>/, 'No <i>');
    unlike( $xc->as_string, qr/<b>/, 'No <b>');

    like( $xc->as_string, qr/graph two\.\.\./, 'Remaining text looks good');

    ok( $xc->strip_tags("*"), "Try to strip i,b at the top of fragment" );

#<i><b>two</b>...</i>

}

{
    my $script = <<'_script_';
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.js"
  type="text/javascript"></script>
<script type="text/javascript">//<![CDATA[
jQuery(function($) {
  $("body").html("<h1>OH HAI</h1>");
});
//]]> </script>
_script_

    my $xc = XHTML::Class->new($script);
    my $xc2 = XHTML::Class->new($script); # Breaks with clone, so clone is wonky.
    # my $xc2 = $xc->clone; # Breaks with clone, so clone is wonky.
    $xc->strip_tags("script");
    like( $xc, qr/jQuery/,
          "Script text remains after strip_tags(script)" );
    $xc2->remove("script");
    is( $xc2, "",
        "Nothing remains after remove(script)" );

}
