package XHTML::Class;
use Moose;
with qw( XHTML::Class::Role::Core
         XHTML::Class::Role::Enpara XHTML::Class::Role::Fix
         XHTML::Class::Role::Info );

use namespace::clean;
use Moose::Exporter;
Moose::Exporter->setup_import_methods( as_is => [qw( xc )] );
use XHTML::Class::Types;
use overload q{""} => sub { +shift->as_string }, fallback => 1;
no warnings "uninitialized";

our $VERSION = "0.01";
our $AUTHORITY = 'cpan:ASHLEY';

use Encode;
use Carp qw( carp croak );
use HTML::Entities;
use HTML::TokeParser::Simple;
use XML::LibXML;
use XML::Catalogs::HTML -libxml;
use HTML::Selector::XPath ();
our $TITLE_ATTR = join("/", __PACKAGE__, $VERSION);
our $FRAGMENT_SELECTOR = "div[title='$TITLE_ATTR']";
our $FRAGMENT_XPATH = HTML::Selector::XPath::selector_to_xpath($FRAGMENT_SELECTOR);

sub xc { __PACKAGE__->new(@_) }

sub debug { 0 }

sub BUILDARGS {
    my ( $class, @arg ) = @_;
    # Standard {} construction.
    return $arg[0] if @arg == 1 and ref($arg[0]) eq "HASH";
    # Single *something* to become source.
    return { source => $arg[0] } if @arg == 1;
    # Plain list.
    return { @arg };
}

sub BUILD {
    my $self = shift;
    my $arg = shift;
    # Barf on bad args.
    $self->meta->has_method($_) or croak "No such attribute: $_" for ( keys %$arg );
    # Convert source to doc.
    $self->_source_string( $arg->{source} );
    $self->_doc($self->_make_sane_doc);
}

has "source" =>
    is => "ro",
    required => 1,
    ;

has "source" =>
    is => "ro",
    required => 1,
    ;

has "source_string" =>
    is => "ro",
    writer => "_source_string",
    isa => "XC::Source",
    coerce => 1,
    ;

has "type" =>
    is => "ro",
    isa => "DWIMtype",
    writer => "_type",
    ;

has "doc" =>
    is => "ro",
    isa => "XML::LibXML::Document",
    writer => "_doc",
    lazy => 1,
    builder => "_make_sane_doc",
    handles => {
        encoding => "actualEncoding",
        findnodes => "findnodes",
        firstChild => "firstChild",
        root => "documentElement",
        as_xhtml => "serialize_html",
        is_valid => "is_valid",
        validate => "validate",
        new_fragment => "createDocumentFragment",
    }
    ;

my @LIBXML_ARG = qw( recover );
has \@LIBXML_ARG =>
    is => "ro",
    isa => "Bool",
    lazy_build => 1,
    ;

has [qw( recover_silently keep_blanks )] =>
    is => "ro",
    isa => "Bool",
    lazy_build => 1,
    ;

has "libxml" =>
    is => "ro",
    isa => "XML::LibXML",
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        my $p = XML::LibXML->new;
        for my $arg ( @LIBXML_ARG )
        {
            my $predicate = "has_$arg";
            $p->$arg($self->$arg) if $self->$predicate;
        }
        # We want it off but defer to caller.
        $self->has_keep_blanks ?
            $p->keep_blanks($self->has_keep_blanks) : $p->keep_blanks(0);
        # We want it on but defer to caller.
        $self->has_recover_silently ?
            $p->recover_silently($self->recover_silently) : $p->recover_silently(1);
        $p;
    },
    handles => [qw( parse_html_string )],
    ;

sub _make_sane_doc {
    my $self = shift;
#    use YAML; die YAML::Dump($self);
    my $doc;
    my $raw = $self->source_string;
    if ( blessed($self->source) =~ /\AXML::LibXML::/ ) # Known good.
    {
        $self->_type("document");
        return $self->parse_html_string($raw);
    }

    if ( $raw =~ /\A(?:<\W[^>]+>|\s+)*<html(?:\s|>)/i )
    {
        $self->_type("document");
    }
    else
    {
        $self->_type("fragment");
        $raw = <<"_EOHTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html><head><title>Untitled $TITLE_ATTR Document</title></head><body>
   <div title="$TITLE_ATTR">$raw</div>
</body></html>
_EOHTML
    }

    my $recover = $self->libxml->recover;
    $self->libxml->recover(0);
    my $well_formed = eval { $self->parse_html_string($raw) };
    $self->libxml->recover($recover);

    return $well_formed if $well_formed;

    $self->parse_html_string($self->_sanitize($raw));
}

sub is_fragment { +shift->type eq 'fragment' }
sub is_document { +shift->type eq 'document' }

sub as_fragment { # force_fragment...? set?
    my $self = shift;
    my ( $fragment ) = $self->findnodes($FRAGMENT_XPATH);
    $fragment ||= [ $self->findnodes("//body") ]->[0]; #$self->body;
    #$fragment ||= $self->body;
    $fragment or croak "No fragment in ", $self->as_xhtml;
    my $out = "";
    $out .= $_->serialize(1,"UTF-8") for $fragment->childNodes; # 321 encoding
    _trim($out);
}

has "bodySADF" =>
    is => "ro",
    isa => "XML::LibXML::Element",
    lazy => 1,
    required => 1,
    default => sub {
        my $self = shift;
        [ $self->findnodes("//body") ]->[0] || croak "No <body/> in $self";
    };

sub body {
    my $self = shift;
    [ $self->doc->findnodes("//body") ]->[0] || croak "No <body/> in $self";
}

has "head" =>
    is => "ro",
    isa => "XML::LibXML::Element",
    lazy => 1,
    required => 1,
    default => sub { 
        [ +shift->doc->findnodes("//head") ]->[0];
    };

sub as_string {
    my $self = shift;
    decode($self->encoding,
           $self->is_fragment ? $self->as_fragment : $self->as_xhtml);
}

sub as_text {
    my $self = shift;
    $self->is_fragment ?
        _trim($self->body->textContent) : _trim($self->doc->textContent);
}

sub _trim {
    s/\A\s+|\s+\z//g for @_;
    wantarray ? @_ : $_[0];
}

sub _sanitize {
    my $self = shift;
    my $fragment = shift or return;
    my $p = HTML::TokeParser::Simple->new(\$fragment);
    my $renew = "";
    my $in_body = 0;
  TOKEN:
    while ( my $token = $p->get_token )
    {
        #warn sprintf("%10s %10s %s\n",  $token->[-1], $token->get_tag, blessed($token));
        #no warnings "uninitialized";
        if ( $self->known($token->get_tag) )
        {
            if ( $token->is_start_tag )
            {
                my @pair;
                for my $attr ( @{ $token->get_attrseq } )
                {
                    next if $attr eq "/";
                    my $value = encode_entities(decode_entities($token->get_attr($attr)));
                    push @pair, join("=",
                                     $attr,
                                     qq{"$value"});
                }
                $renew .= "<" . join(" ", $token->get_tag, @pair);
                $renew .= ( $token->get_attr("/") || $self->empty($token->get_tag) ) ? "/>" : ">";
            }
            else
            {
                $renew .= $token->as_is;
            }
        }
        elsif ( $token->is_declaration or $token->is_pi )
        {
            $renew .= $token->as_is;
        }
        else
        {
            $renew .= encode_entities(decode_entities($token->as_is),'<>"&');
        }
    }
    return $renew;
}

# rename css_to_xpath?
sub selector_to_xpath {
    my $self = shift;
    my $selector = shift;
    return $selector if $selector =~ m,\A/,; # Already definitely xpath.
    unless ( $selector )
    {
        my $base = $self->is_fragment ? $FRAGMENT_SELECTOR : "body";
        $selector = "$base *";
        #$selector = "$base, $base *";
    }
    HTML::Selector::XPath::selector_to_xpath($selector);
}

1;

__END__

=pod

=head1 Name

XHTML::Class - (alpha software) XHTML with munging, validation, tranformations, and DWIM upgrading of HTML in a L<XML::LibXML> object.

=head1 Synopsis

 use warnings;
 use strict;
 use XHTML::Class;
 my $xc = XHTML::Class
    ->new("This is naked\n\ntext for making into paragraphs.");
 print $xc->enpara, $/;
 
 # <p>This is naked</p>
 #
 # <p>text for making into paragraphs.</p>

 use XHTML::Class;
 $xc = xc(q{
    <blockquote>Quotes should probably have paras.</blockquote>
 });
 $xc->enpara("blockquote");
 print $xc->as_xhtml, $/;
 
 # <blockquote>
 #   <p>Quotes should probably have paras.</p>
 # </blockquote>

 $xc = XHTML::Class
     ->new('<i><a href="#"><b>Something</b></a>.</i>');
 
 print $xc->strip_tags('a');
 # <i><b>Something</b>.</i>

 print xc("<p><Q&A>");
 # <p>&lt;Q&amp;A&gt;</p>

=head1 Description

You create an L<XHTML::Class> object with the method L</new> or the convenience function L</xc>. The typical, simple way, to use it is with a single argument.

 $xhtml = XHTML::Class->new($something);
 # or
 $xhtml = xc($something); # Returns the same thing.

The C<$something> comes through a coercion map so there is a large variety of things that you can pass to L</new>. Acceptable arguments includeE<ndash>

=over 4

=item * Plain text string.

=item * Stringified HTML doc.

=item * L<Path::Class::File> object or any object that can C<slurp>.

=item * L<HTML::TreeBuilder> object or any object that can C<as_HTML>.

=item * L<IO::File> or any object that can C<getlines>.

=item * An L<XML::LibXML::Document> or L<XML::LibXML::Element> or any object that can serialize to a string.

=item * Any object that can C<as_text> or C<as_string>.

=item * A L<URI> object: this will make an L<LWP::UserAgent> C<get>-E<gt>C<decoded_content> request.

=back

You can use CSS expressions to most of the methods. E.g., to only enpara the contents of div tags with a class of "enpara" -- C<< E<lt>div class="enpara"/E<gt> >> -- you could do this-

 print $xc->enpara("div.enpara");

To do the contents of all blockquotes and divs-

 print $xc->enpara("div, blockquote");

Alterations to the XHTML in the object are persistent.

 my $xc = XHTML::Class
     ->new('<script>alert("OH HAI")</script>');
 $xc->strip_tags('script');

Will remove the script tagsE<mdash>not the script content thoughE<mdash>so the next time you call anything that returns the stringified object the changes will remainE<ndash>

 print $xc->as_string, $/;
 # alert("OH HAI")

Well... really you'll get C<< E<lt>![CDATA[alert(&quot;OH HAI&quot;)]]E<gt> >>.

=head1 Methods

=over 4

=item * new

In addition to the single argument construction, you can provide a hash ref (or hash style list) of further settingsE<ndash>

 xc($string);
 xc({ source => $string }); # Same thing.

 XHTML::Class->new($path_class);
 XHTML::Class->new(source => $path_class); # Same thing.

=back

=head1 Code Repository

L<http://github.com/pangyre/p5-xhtml-class>.

=head1 See Also


=head1 Author

Ashley Pond V E<middot> ashley.pond.v@gmail.com E<middot> L<http://pangyresoft.com>.

=head1 License

You may redistribute and modify this package under the same terms as Perl itself.

=head1 Disclaimer of Warranty

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut
