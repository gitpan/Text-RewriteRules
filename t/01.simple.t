# -*- cperl -*-
use Test::More tests => 22;
use Text::RewriteRules;

## Replace
RULES first
a==>b
ENDRULES

is(first("bar"),"bbr");

## Replace with references...
RULES second
a(\d+)==>$1
ENDRULES

is(second("a342"),"342");
is(second("b342"),"b342");
is(second("ba2cd"),"b2cd");


## Conditional
RULES third
b(a+)b==>bbb!! length($1)>5
ENDRULES

is(third("bab"), "bab");
is(third("baab"), "baab");
is(third("baaab"), "baaab");
is(third("baaaab"), "baaaab");
is(third("baaaaab"), "baaaaab");
is(third("baaaaaab"), "bbb");
is(third("baaaaaaab"), "bbb");


## Eval Conditional
RULES fourth
b(\d+)=e=>'b' x $1 !! $1 > 5
ENDRULES

is(fourth("b1"), "b1");
is(fourth("b2"), "b2");
is(fourth("b5"), "b5");
is(fourth("b6"), "bbbbbb");
is(fourth("b8"), "bbbbbbbb");


## Eval
RULES fifth
b(\d+)=e=>'b' x $1
ENDRULES

is(fifth("b1"), "b");
is(fifth("b2"), "bb");
is(fifth("b5"), "bbbbb");
is(fifth("b8"), "bbbbbbbb");


### Don't like this
### the return value should be used, I think.
RULES sixth
=b=> $_="AA${_}AA"
ENDRULES

is(sixth("foo"),"AAfooAA");


## Last...
RULES seventh
bbbbbb=l=>
b==>bb
ENDRULES

is(seventh("b"),"bbbbbb");
