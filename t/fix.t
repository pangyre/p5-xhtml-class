use warnings;
use strict;
use Test::More skip_all => "Fix role isn't back in the mix yet";
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Class;
use YAML;

local $/ = "\n::TEST::DATA::\n";

while ( <DATA> )
{
    chomp;
    my ( $input, $expected ) = _trim(split /::/)
        or next;

    my $xc = XHTML::Class->new(\$input);
    $xc->fix;
    is( _trim($xc->as_string), _trim($expected),
        length($expected) > 30 ?
        substr($expected, 0, 27) . "..." : $expected
      );
    #diag(YAML::Dump($xc));
}

done_testing();

__DATA__
<p>OH HAI!
::
<p>OH HAI!
</p>

::TEST::DATA::

<img src='/moo.cow'>
::
<img src="/moo.cow" alt="/moo.cow"/>

::TEST::DATA::
