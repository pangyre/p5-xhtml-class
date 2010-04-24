use Moose;
use Moose::Util::TypeConstraints;
use namespace::clean;

# use Params::Coerce ();
use URI ();
use XML::LibXML;

subtype "XC::LibXML::Element" => as class_type("XML::LibXML::Element");
subtype "XC::URI" => as class_type("URI");
subtype "XC::Path::Class" => as class_type("Path::Class::File");

subtype "XC::Document" => as class_type("XML::LibXML::Document");
coerce  "XC::Document"
    => from "Str"
        => via { _from_string($_) }
    => from "XC::LibXML::Element"
        => via { _from_string($_->serialize) }
    => from "XC::URI"
        => via {
            require LWP::Simple;
            _from_string(LWP::Simple::get($_));
        }
    => from "XC::Path::Class"
        => via {
            _from_string( scalar $_->slurp );
        }
    ;

sub _from_string {
    my $str = shift;
    XML::LibXML->new->parse_html_string($str);
}


1;

__END__
Object
  can getline?

    => from "XML::LibXML::Document"
    => via { $_ }
    => from "XML::LibXML::Element"
    => via { $_ }
    => from "URI"
    => via { $_ }
    => from "Path::Class"
    => via { $_ }

  use HTTP::Headers  ();
  use Params::Coerce ();
  use URI            ();

  subtype 'My::Types::HTTP::Headers' => as class_type('HTTP::Headers');




subtype 'My::Types::HTTP::Headers' => as class_type('HTTP::Headers');
    required => 1,
  coerce 'My::Types::URI'
      => from 'Object'
    => via { $_->isa('URI')
                   ? $_
                   : Params::Coerce::coerce( 'URI', $_ ); }
      => from 'Str'
    => via { URI->new( $_, 'http' ) };
