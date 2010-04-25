use warnings;
use strict;
use Test::More;
use XHTML::Class;
# use YAML;
use Encode;
use utf8;

local $/ = "\n::TEST::DATA::\n";

while ( my $pair = <DATA> )
{
    $pair = decode_utf8($pair);
    my ( $input, $expected ) = split /::/, $pair;
    my $xc = XHTML::Class->new($input);

    is($xc, XHTML::Class::_trim($expected),
       _substr($expected) );

#    is( _trim($xc->as_string),
#       _trim($expected),
#        _substr($expected)
#      );
    # diaag( YAML::Dump($xc) );
}

done_testing();

exit 0;

sub _substr {
    my ( $copy ) = encode("UTF8", shift);
    $copy =~ s/[^\S ]+//g; # Flatten for nicer verbosity display.
    length($copy) > 60 ?
        substr($copy, 0, 57) . "..." : $copy;
}


=head1 NOTES

Should URI escape fix-up only happen in ->fix?

=cut

__DATA__

OH HAI!
::
OH HAI!

::TEST::DATA::

OH<br>HAI!
::
OH<br />HAI!

::TEST::DATA::

<p>OH HAI!
::
<p>OH HAI!
</p>

::TEST::DATA::

Naked entities: <Q&A>
::
Naked entities: &lt;Q&amp;A&gt;

::TEST::DATA::

<b>Already encoded: &lt;Q&amp;A&gt;</b>
::
<b>Already encoded: &lt;Q&amp;A&gt;</b>

::TEST::DATA::

<img src=no-quote.gif alt='<p class="asterix">*</p>' width=10%>
::
<img src="no-quote.gif" alt="&lt;p class=&quot;asterix&quot;&gt;*&lt;/p&gt;" width="10%" />

::TEST::DATA::

<a href="/moo?cow=cow&flag=burned&site=1">åß∂ƒ</a>
::
<a href="/moo?cow=cow&amp;flag=burned&amp;site=1">åß∂ƒ</a>
