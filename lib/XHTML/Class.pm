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

our $VERSION = "0.90_01";
our $AUTHORITY = 'cpan:ASHLEY';

use Encode;
use Carp qw( carp croak );
use XML::LibXML;
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
    elsif ( $raw =~ /\A(?:<\W[^>]+>|\s+)*<html(?:\s|>)/i )
    {
        $self->_type("document");
        return $self->parse_html_string($raw);
    }
    else
    {
        $self->_type("fragment");
        return $self->parse_html_string(<<"_EOHTML");
<html><head><title>Untitled $TITLE_ATTR Document</title></head><body>
   <div title="$TITLE_ATTR">$raw</div>
</body></html>
_EOHTML
    }
#    return $doc;
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

    else
    $selector =~ m,\A/, ?
        $selector :

Definitions:
 Fragment, <b>anything</b> in the <body>

=head1 NAME

XHTML::Util - (alpha software) powerful utilities for common but difficult to nail HTML munging.

=head2 VERSION

0.99_08

=head1 SYNOPSIS

 use strict;
 use warnings;
 use XHTML::Util;
 my $xu = XHTML::Util
    ->new(\"This is naked\n\ntext for making into paragraphs.");
 print $xu->enpara, $/;
 
 # <p>This is naked</p>
 #
 # <p>text for making into paragraphs.</p>

 $xu = XHTML::Util
     ->new(\"<blockquote>Quotes should probably have paras.</blockquote>");
 print $xu->enpara("blockquote");
 
 # <blockquote>
 #   <p>Quotes should probably have paras.</p>
 # </blockquote>

 $xu = XHTML::Util
     ->new(\'<i><a href="#"><b>Something</b></a>.</i>');
 
 print $xu->strip_tags('a');
 # <i><b>Something</b>.</i>

=head1 DESCRIPTION

You can use CSS expressions to most of the methods. E.g., to only enpara the contents of div tags with a class of "enpara" -- C<< E<lt>div class="enpara"/E<gt> >> -- you could do this-

 print $xu->enpara("div.enpara");

To do the contents of all blockquotes and divs-

 print $xu->enpara("div, blockquote");

Alterations to the XHTML in the object are persistent.

 my $xu = XHTML::Util
     ->new(\'<script>alert("OH HAI")</script>');
 $xu->strip_tags('script');

Will remove the script tagsE<mdash>not the script content thoughE<mdash>so the next time you call anything that returns the stringified object the changes will remainE<ndash>

 print $xu->as_string, $/;
 # alert("OH HAI")

Well... really you'll get C<< E<lt>![CDATA[alert(&quot;OH HAI&quot;)]]E<gt> >>.

=head1 METHODS

=head2 new

Creates a new C<XHTML::Util> object.

=head2 strip_tags

Why you might need this-

 my $post_title = "I <3 <a href="http://icanhascheezburger.com/">kittehs</a>";
 my $blog_link = some_link_maker($post_title);
 print $blog_link;

 <a href="/oh-noes">I <3 <a href="http://icanhascheezburger.com/">kittehs</a></a>

That isn't legal so there's no definition for what browsers should do with it. Some sort of tolerate it, some don't. It's never going to be a good user experience.

What you can do is something like thisE<ndash>

 my $post_title = "I <3 <a href="http://icanhascheezburger.com/">kittehs</a>";
 my $safe_title = $xu->strip_tags($post_title, ["a"]);
 # Menu link should only go to the single post page.
 my $menu_view_title = some_link_maker($safe_title);
 # No need to link back to the page you're viewing already.
 my $single_view_title = $post_title;

=head2 remove

Takes a CSS selector string. Completely removes the matched nodes, including their content. This differs from L</strip_tags> which retains the child nodes intact and only removes the tags proper.

 # Remove <center/> tags and external images.
 my $cleaned = $xu->remove("center, img[src^='http']");

=head2 traverse

Walks the given nodes and executes the given callback. Can be called with a selector or without. If called with a selector, the callback sub receives the selected nodes as its arguments.

 $xu->traverse("div.fancy", sub { my $div_node = shift });

Without a selector it receives the document root.

 $xu->traverse(sub { my $root = shift });

=head2 translate_tags

[Not implemented.] Translates one tag to another.

=head2 remove_style

[Not implemented.] Removes styles from matched nodes. To remove all style from a fragment-

 $xu->remove_style("*");

(Should also remove style sheets, yes?)

=head2 inline_stylesheets

[Not implemented.] Moves all linked stylesheet information into inline style attributes. This is useful, for example, when distributing a document fragment like an RSS/Atom feed and having it match its online appearance.

=head2 sanitize

[Not implemented.] Upgrades old or broken HTML to valid XHTML.

=head2 fix

[Partially implemented.] Attempts to make many known problems go away. E.g., entity escaping, missing alt attributes of images, etc.

=head2 validate

Validates a given document or fragment (which is actually contained in a full document) against a DTD provided by name or, if none is provided, it will validate against F<xhtml1-transitional>. Uses L<XML::LibXML>'s validate under the covers.

=head2 is_valid

A non-fatal version of L</validate>. Returns true on success, false on failure.

=head2 enpara

To add paragraph markup to naked text. There are many, many implementations of this basic idea out there as well as many like Markdown which do much more. While some are decent, none is really meant to sling arbitrary HTML and get DWIM behavior from places where it's left out; every implementation I've seen either has rigid syntax or has beaucoup failure prone edge cases. Consider these-

 Is this a paragraph
 or two?

 <p>I can do HTML when I'm paying attention.</p>
 <p style="color:#a00">Or I need to for some reason.</p>
 Oh, I stopped paying attention... What happens here? Or <i>here</i>?

 I'd like to see this in a paragraph so it's legal markup.
 <pre>
 now
 this
 should


 not be touched!
 </pre>I meant to do that.

With C<< XHTML::Util-E<gt>enpara >> you will get-

 <p>Is this a paragraph<br/>
 or two?</p>

 <p>I can do HTML when I'm paying attention.</p>
 <p style="color:#a00">Or I need to for some reason.</p>
 <p>Oh, I stopped paying attention... What happens here? Or <i>here</i>?</p>

 <p>I'd like to see this in a paragraph so it's legal markup.</p>
 <pre>
 now
 this
 should
 
 
 not be touched!
 </pre>
 <p>I meant to do that.</p>

=head2 parser

The L<XML::LibXML> parser object used to parse (X)HTML.

=head2 doc

The L<XML::LibXML::Document> object created from input.

=head2 root

The documentElement of the L<XML::LibXML::Document> object.

=head2 text

The C<textContent> of the root node.

=head2 head

The head element.

=head2 body

The body element.

Note there is always an implicit head and body even with fragments because libxml creates them, well, we ask it to do so.

=head2 as_fragment

Returns the original (intent-wise) fragment or the elements within the body if starting with a full document.

=head2 as_string

Stringified version of object. If the object was created from an HTML fragment, a fragment will be returned.

=head2 debug

Yep. 1-5 with higher giving more info to STDERR.

=head2 is_document

Returns true if the originally parsed item was a full HTML document.

=head2 is_fragment

Returns true if the originally parsed item was a fragment.

=head2 clone

=head2 same_same

Takes another XHTML::Util object or the valid argument to create one. Attempts to determine if the resulting object is the same as the calling object. E.g.,

 print $xu->same_same(\"<p>OH HAI</p>") ?
     "Yepper!\n" : "Noes...\n";

=head2 tags

Returns a list of all known HTML tags. Please ignore method. I'm not sure it's a good idea, well named, or will remain.

=head2 selector_to_xpath

This wraps L<selector_to_xpath HTML::Selector::Xpath/selector_to_xpath>. Not really meant to be used but exposed in case you want it.

 print $xu->selector_to_xpath("form[name='register'] input[type='password']");
 # //form[@name='register']//input[@type='password']

=head1 TO DO

I think the default doc should be \"". There is no reason to jump through that hoop if wanting to build up something from scratch.

Finish spec and tests. Get it running solid enough to remove alpha label. Generalize the argument handling. Provide optional setting or methods for returning nodes instead of serialized content. Improve document/head related handling/options.

I can see this being easier to use functionally. I haven't decided on the argspec or method--E<gt>sub approach for that yet. I think it's a good idea.

=head1 BUGS AND LIMITATIONS

Plenty, I am certin. I am not adept with encodings and I would love any bug reports or fixes to anything I've overlooked.

The code herein is not well tested or at least not well tested in this incarnation. Bug reports and good feedback are B<adored>.

=head1 SEE ALSO

L<XML::LibXML>, L<HTML::Tagset>, L<HTML::Entities>, L<HTML::Selector::XPath>, L<HTML::TokeParser::Simple>, L<CSS::Tiny>.

CSS W3Schools, L<http://www.w3schools.com/Css/default.asp>, Learning CSS at W3C, L<http://www.w3.org/Style/CSS/learning>.

=head1 REPOSITORY

git://github.com/pangyre/p5-xhtml-util

=head1 AUTHOR

Ashley Pond V, ashley at cpan.org.

=head1 COPYRIGHT & LICENSE

Copyright (E<copy>) 2006-2009.

This program is free software; you can redistribute it or modify it or both under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by applicable law. Except when otherwise stated in writing the copyright holders or other parties provide the software "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the software is with you. Should the software prove defective, you assume the cost of all necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may modify and/or redistribute the software as permitted by the above licence, be liable to you for damages, including any general, special, incidental, or consequential damages arising out of the use or inability to use the software (including but not limited to loss of data or data being rendered inaccurate or losses sustained by you or third parties or a failure of the software to operate with any other software), even if such holder or other party has been advised of the possibility of such damages.

=cut

typedef enum {
    XML_ELEMENT_NODE=           1,
    XML_ATTRIBUTE_NODE=         2,
    XML_TEXT_NODE=              3,
    XML_CDATA_SECTION_NODE=     4,
    XML_ENTITY_REF_NODE=        5,
    XML_ENTITY_NODE=            6,
    XML_PI_NODE=                7,
    XML_COMMENT_NODE=           8,
    XML_DOCUMENT_NODE=          9,
    XML_DOCUMENT_TYPE_NODE=     10,
    XML_DOCUMENT_FRAG_NODE=     11,
    XML_NOTATION_NODE=          12,
    XML_HTML_DOCUMENT_NODE=     13,
    XML_DTD_NODE=               14,
    XML_ELEMENT_DECL=           15,
    XML_ATTRIBUTE_DECL=         16,
    XML_ENTITY_DECL=            17,
    XML_NAMESPACE_DECL=         18,
    XML_XINCLUDE_START=         19,
    XML_XINCLUDE_END=           20
#ifdef LIBXML_DOCB_ENABLED
   ,XML_DOCB_DOCUMENT_NODE=     21
#endif
} xmlElementType;


use HTML::Entities;
our %Charmap = %HTML::Entities::entity2char;
delete @Charmap{qw( amp lt gt quot apos )};



translate_tags

traverse("/*") -> callback

strip_styles(* or [list])
strip_attributes()

inline_stylesheets(names/paths)

fragment_to_xhtml

We WILL NOT be covering other well known and well done implementations like HTML::Entities or URI::Escape

   use Rose::HTML::Util qw(:all);

   $esc = escape_html($str);
   $str = unescape_html($esc);

   $esc = escape_uri($str);
   $str = unescape_uri($esc);

   $comp = escape_uri_component($str);

   $esc = encode_entities($str);

# Two ways to get doc together. Pass through HTML::TokeParser first to
# correct for nothing but HTML and escape the rest.

# Two ways to handle the overview: destructive or exception. Just try
# to do it and ignore errors which might mean erasing content, or
# throw them.
# translate div p
# replace //a@href... || a[href^=...] 'content' || call back

HTML TO XHTML will have to strip deprecated shite like center and font.


12212g

VALID_ONLY FLAG?

DEBUG:

   5 EVERYTHING
   4
   3
   2
   1

SANITIZE IS BREAKING THE XML DTD HEADERS AND CDATA

Mention HTML::Restrict

    Test::Harness

Things like wrap() should be quite easy to add...

NOTES, leftovers.
#my $canTighten = \%HTML::Tagset::canTighten;
#my $isHeadElement = \%HTML::Tagset::isHeadElement;
#my $isHeadOrBodyElement = \%HTML::Tagset::isHeadOrBodyElement;
#my $isList = \%HTML::Tagset::isList;
#my $isTableElement = \%HTML::Tagset::isTableElement;
#my $p_closure_barriers = \@HTML::Tagset::p_closure_barriers;

ALL METHODS take a selector and default to * (OR //body/*?) otherwise.


This will wreck XML and probably XHTML with a custom DTD too. It uses L<HTML::Tagset>'s conception of what valid tags are. This is not optimal but it is easier than DTD handling. It might improve to more automatic detection in the future.

I have used many of these methods and snippets in many projects and I'm tired of recycling them. Some are extremely useful and, at least in the case of L</enpara>, better than any other implementation I've been able to find in any language.

