# -*- cperl -*-
use Test::More tests => 6;
use Text::RewriteRules;

## Replace
MRULES first
b==>bb
r==>
ENDRULES

is(first("bar"),"bba");



## Replace (ignore case)
MRULES ifirst
b=i=>bb
r==>
ENDRULES

is(ifirst("Bar"),"bba");



## Eval
MRULES second
b=eval=>'b' x 2
r==>
ENDRULES

is(second("bar"),"bba");



## Eval with ignore case
MRULES isecond
(b)=i=e=>$1 x 2
r==>
ENDRULES

is(isecond("Bar"),"BBa");



MRULES third
a==>b!!1
ENDRULES

is(third("bab"),"bbb");


## use of flag instead of MRULES
RULES/m fourth
b==>bb
r==>
ENDRULES

is(fourth("bar"),"bba");
