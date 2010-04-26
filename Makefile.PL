use strict;
use inc::Module::Install;

name "XHTML-Class";
license 'perl';
all_from "lib/XHTML/Class.pm";
repository "git://github.com/pangyre/p5-xhtml-class";

requires "Encode" => 2;
requires "HTML::Tagset" => 3.02;
requires "XML::LibXML" => "1.69"; # Is this where unicode was all normalized?
requires "XML::Normalize::LibXML";

requires "Scalar::Util";
requires "HTML::Tagset" => 3.02;
# requires "HTML::DTD" => 0.03; # below?
requires "XML::Catalogs::HTML" => 1;
requires "HTML::Entities";
requires "CSS::Tiny";
requires "HTML::Selector::XPath" => "0.04";
requires "HTML::TokeParser::Simple";
recommends "LWP::UserAgent";

test_requires "Test::More" => 0.5;
test_requires "Test::Exception" => 0.2;
test_requires "File::Spec" => 3;
test_requires "HTTP::Daemon";

if ( $Module::Install::AUTHOR )
{
    system("pod2text lib/XHTML/Class.pm > README") == 0
        or die "Couldn't update the README";
}

auto_install;
WriteAll;

__END__

2.6.2?
    XML::LibXML::LIBXML_DOTTED_VERSION
2.7.0 better


