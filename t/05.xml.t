# -*- cperl -*-
use Test::More tests => 7;
use Text::RewriteRules;

RULES first
[[:XML:]]==>XML
ENDRULES

RULES Xsecond
[[:XML(d):]]==>XML
ENDRULES

RULES Ysecond
[[:XML(c):]]==>XML
ENDRULES

RULES Zsecond
[[:XML(b):]]==>XML
ENDRULES

RULES third
[[:XML:]]=e=>$+{TAG}
ENDRULES

my $in = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in2 = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";

is(first($in),"ola XML ola");
is(first($in2),"ola XML ola XML ola");

is(Xsecond($in),"ola <a hmm =\"hmm\"><b>XML<c>o</c></b></a> ola");
is(Ysecond($in),"ola <a hmm =\"hmm\"><b><d zbr='foo'/>XML</b></a> ola");
is(Zsecond($in),"ola <a hmm =\"hmm\">XML</a> ola");
is(Zsecond($in2),"ola <a hmm =\"hmm\">XML</a> ola <a hmm =\"hmm\">XML</a> ola");

is(third($in),"ola a ola");

