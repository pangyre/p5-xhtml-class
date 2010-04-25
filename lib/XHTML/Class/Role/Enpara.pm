package XHTML::Class::Role::Enpara;
use Moose::Role;
# no warnings "uninitialized";
use namespace::autoclean;
use Carp;
requires qw( known block_level );

sub enpara {
    my $self = shift;
    my $xpath = $self->_make_selector(+shift);
    my $root = $self->root;
    my $doc = $self->doc;

  NODE:
    for my $designated_enpara ( $root->findnodes("$xpath") )
    {
        # warn "FOUND ", $designated_enpara->nodeName, $/;
        # warn "*********", $designated_enpara->toString if $self->debug > 2;
        next unless $designated_enpara->nodeType == 1;
        next NODE if $designated_enpara->nodeName eq 'p';
        if ( $designated_enpara->nodeName eq 'pre' )  # I don't think so, honky.
        {
            # Expand or leave it alone? or ->validate it...?
            carp "It makes no sense to enpara within a <pre/>; skipping";
            next NODE;
        }
        next unless $self->block_level($designated_enpara->nodeName);

        $self->_enpara_this_nodes_content($designated_enpara, $doc);
    }
    $self->_enpara_this_nodes_content($root, $doc);
    # $self->_return;
    $self;
}

sub _enpara_this_nodes_content {
    my ( $self, $parent, $doc ) = @_;
    my $lastChild = $parent->lastChild;
    my @naked_block;
    for my $node ( $parent->childNodes )
    {
        if ( $self->block_level($node->nodeName)
             or
             $node->nodeName eq "a" # special case block level, so IGNORE
             and
             grep { $_->nodeName eq "img" } $node->childNodes
             )
        {
            next unless @naked_block; # nothing to enblock
            my $p = $doc->createElement("p");
            $p->setAttribute("enpara","enpara");
            $p->setAttribute("line",__LINE__) if $self->debug > 4;
            $p->appendChild($_) for @naked_block;
            $parent->insertBefore( $p, $node )
                if $p->textContent =~ /\S/;
            @naked_block = ();
        }
        elsif ( $node->nodeType == 3
                and
                $node->nodeValue =~ /(?:[^\S\n]*\n){2,}/
                )
        {
            my $text = $node->nodeValue;
            my @text_part = map { $doc->createTextNode($_) }
                split /([^\S\n]*\n){2,}/, $text;

            my @new_node;
            for ( my $x = 0; $x < @text_part; $x++ )
            {
                if ( $text_part[$x]->nodeValue =~ /\S/ )
                {
                    push @naked_block, $text_part[$x];
                }
                else # it's a blank newline node so _STOP_
                {
                    next unless @naked_block;
                    my $p = $doc->createElement("p");
                    $p->setAttribute("enpara","enpara");
                    $p->setAttribute("line",__LINE__) if $self->debug > 4;
                    $p->appendChild($_) for @naked_block;
                    @naked_block = ();
                    push @new_node, $p;
                }
            }
            if ( @new_node )
            {
                $parent->insertAfter($new_node[0], $node);
                for ( my $x = 1; $x < @new_node; $x++ )
                {
                    $parent->insertAfter($new_node[$x], $new_node[$x-1]);
                }
            }
            $node->unbindNode;
        }
        elsif ( $node->nodeName !~ /\Ahead|body\z/ ) # Hack? Fix real reason? 321
        {
            push @naked_block, $node; # if $node->nodeValue =~ /\S/;
        }

        if ( $node->isSameNode( $lastChild )
             and @naked_block )
        {
            my $p = $doc->createElement("p");
            $p->setAttribute("enpara","enpara");
            $p->setAttribute("line",__LINE__) if $self->debug > 4;
            $p->appendChild($_) for ( @naked_block );
            $parent->appendChild($p) if $p->textContent =~ /\S/;
        }
    }

    my $newline = $doc->createTextNode("\n");
    my $br = $doc->createElement("br");

    for my $p ( $parent->findnodes('//p[@enpara="enpara"]') )
    {
        $p->removeAttribute("enpara");
        $parent->insertBefore( $newline->cloneNode, $p );
        $parent->insertAfter( $newline->cloneNode, $p );

        my $frag = $doc->createDocumentFragment();

        my @kids = $p->childNodes();
        for ( my $i = 0; $i < @kids; $i++ )
        {
            my $kid = $kids[$i];
            next unless $kid->nodeName eq "#text";
            my $text = $kid->nodeValue;
            $text =~ s/\A\r?\n// if $i == 0;
            $text =~ s/\r?\n\z// if $i == $#kids;

            my @lines = map { $doc->createTextNode($_) }
                split /(\r?\n)/, $text;

            for ( my $i = 0; $i < @lines; $i++ )
            {
                $frag->appendChild($lines[$i]);
                unless ( $i == $#lines
                         or
                         $lines[$i]->nodeValue =~ /\A\r?\n\z/ )
                {
                    $frag->appendChild($br->cloneNode);
                }
            }
            $kid->replaceNode($frag);
        }
    }
}


1;

__END__

package XHTML::Util;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( xu );
use warnings;
use strict;
no warnings "uninitialized";
use Carp;
use XML::LibXML;
use XML::Catalogs::HTML;
    XML::Catalogs::HTML->notify_libxml();
use HTML::Tagset 3.02 ();
use HTML::Entities qw( encode_entities decode_entities );
use HTML::Selector::XPath ();
use HTML::DTD;
use Path::Class;
use Encode;
use Scalar::Util qw( blessed );
use HTML::TokeParser::Simple;
use XML::Normalize::LibXML qw( xml_normalize );
use overload q{""} => sub { +shift->as_string }, fallback => 1;

our $VERSION = "0.90";
our $AUTHORITY = 'cpan:ASHLEY';
our $TITLE_ATTR = join("/", __PACKAGE__, $VERSION);

our $FRAGMENT_SELECTOR = "div[title='$TITLE_ATTR']";
our $FRAGMENT_XPATH = HTML::Selector::XPath::selector_to_xpath($FRAGMENT_SELECTOR);


