# -*- cperl -*-
use Test::More tests => 2;
use Text::RewriteRules;

## Replace
MRULES first
b==>bb
a==>a
r==>
ENDRULES

is(first("bar"),"bba");

## Eval
MRULES second
b=eval=>'b' x 2
a==>a
r==>
ENDRULES

is(second("bar"),"bba");
