use warnings;
use strict;
use Test::More;
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Class;

{
    my $before = Path::Class::File->new("$FindBin::Bin/files/enpara-complex-before.txt")->slurp;
    my $after = Path::Class::File->new("$FindBin::Bin/files/enpara-complex-after.txt")->slurp;

    cmp_ok( XHTML::Class::_trim($before), "ne", XHTML::Class::_trim($after),
            "Before and after differ");

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new files/enpara-complex-before.txt->slurp" );

    #    $xc->debug(3);

#    is(XHTML::Class::_trim($xc->as_string),
#       XHTML::Class::_trim($before),
#       "Original content matches stringified object");

    ok( my $enparaed = $xc->enpara,
        "Enpara'ing the content" );

    is( $enparaed, $after,
        "Enpara'ed content of 'before' matches 'after'" );

    ok( $xc->is_valid,
        "Document validates" ) or diag($xc->as_xhtml);

}

__END__

my $src = _baseline();

ok( my $paras = $xc->enpara($src),
    "Enpara the test text"
    );

# diag("PARAS: " . $paras) if $ENV{TEST_VERBOSE};

is($paras, Encode::decode_utf8(_fixed()),
   "enpara doing swimmingly");

sub _fixed {
    q{<p>Not in<br/>
the first abutting.</p>
<p>Did it manually here.</p>
<p><b>Didn't</b> <i>do it.</i></p>
<p>Did it manually again in the third.</p><pre>
This is the fourth block and has


“triple spacing in it and an &amp;”
</pre>
<p>Didn't do it here<br/>
in<br/>
the fifth.</p>
<p>Did it here in
the sixth mashed up against the fifth so we
could not possibly split on whitespace.</p><hr/>
<p>Have a <b>bold</b> here that needs a paragraph.</p>

<p>also need</p>

<p>three in a row</p>

<p>and four for that matter</p>
<p>real para back into the mix</p>
<p>And two in a row <a href="http://localhost/a/12" title="Read&#10;more of " so="So" i="I" kinda="kinda" have="have" a="a" crush="">[read more]</a></p>

<p>
  <b>asdf</b>
</p>

<p>!</p>

<p>?</p>};
}

sub _baseline {
    q{Not in
the first abutting.<p>Did it manually here.</p>

<b>Didn't</b> <i>do it.</i>

<p>Did it manually again in the third.</p>

<pre>
This is the fourth block and has


“triple spacing in it and an &amp;”
</pre>
Didn't do it here
in
the fifth.<p>Did it here in
the sixth mashed up against the fifth so we
could not possibly split on whitespace.</p>

<hr/>

Have a <b>bold</b> here that needs a paragraph.

also need

three in a row

and four for that matter

<p>real para back into the mix</p>

And two in a row <a href="http://localhost/a/12" title="Read
more of "So I kinda have a crush">[read more]</a>

<b>asdf</b>

!

?

};
}

__END__

    my $diff = Algorithm::Diff->new( [ split /\n/, $enparaed ],
                                     [ $after->slurp ] );

    while ( $diff->Next() )
    {
        next   if  $diff->Same();
        my $sep = '';
        if(  ! $diff->Items(2)  ) {
            diag(sprintf "%d,%dd%d\n",
                $diff->Get(qw( Min1 Max1 Max2 )));
        } elsif(  ! $diff->Items(1)  ) {
            diag(sprintf "%da%d,%d\n",
                $diff->Get(qw( Max1 Min2 Max2 )));
        } else {
            $sep = "---\n";
            diag(sprintf "%d,%dc%d,%d\n",
                $diff->Get(qw( Min1 Max1 Min2 Max2 )));
        }
        diag( "< $_" )  for  $diff->Items(1);
        diag( $sep );
        diag( "> $_" )  for  $diff->Items(2);
    }
