# -*- cperl -*-
use Test::More tests => 6;
use Text::RewriteRules;

RULES first
[[:PB:]]==>+
ENDRULES

RULES second
[[:BB:]]==>*
ENDRULES

RULES third
[[:CBB:]]==>#
ENDRULES

my $in = "ola (a (b)(d zbr='foo')(c)) munto (c()()ba)((())) ola";
my $in2 = "ola ((a hmm =\"hmm\")(b)(d zbr='foo'/)(c)) lua ((/c)(/b)(/a) 
    ola (a hmm =\"hmm\")(b)(d zbr='foo'/))(c)(/c)(aaa()(/a) ola";

my $on = "ola [a [b][d zbr='foo'][c]] munto [c[][]ba][[[]]] ola";
my $on2 = "ola [[a hmm =\"hmm\"][b][d zbr='foo'/][c]] lua [[/c][/b][/a] 
    ola [a hmm =\"hmm\"][b][d zbr='foo'/]][c][/c][aaa[][/a] ola";

my $un = "ola {a {b}{d zbr='foo'}{c}} munto {c{}{}ba}{{{}}} ola";
my $un2 = "ola {{a hmm =\"hmm\"}{b}{d zbr='foo'/}{c}} lua {{/c}{/b}{/a} 
    ola {a hmm =\"hmm\"}{b}{d zbr='foo'/}}{c}{/c}{aaa{}{/a} ola";

is(first($in),"ola + munto ++ ola");
is(first($in2),"ola + lua +++(aaa++ ola");

is(second($on),"ola * munto ** ola");
is(second($on2),"ola * lua ***[aaa** ola");

is(third($un),"ola # munto ## ola");
is(third($un2),"ola # lua ###{aaa## ola");

#is(second($in),"ola <a hmm =\"hmm\"><b>XML<c>o</c></b></a> ola");
#is(second($in),"ola <a hmm =\"hmm\"><b><d zbr='foo'/>XML</b></a> ola");
#is(second($in),"ola <a hmm =\"hmm\">XML</a> ola");
#is(second($in2),"ola <a hmm =\"hmm\">XML</a> ola <a hmm =\"hmm\">XML</a> ola");

#is(third($in),"ola a ola");

