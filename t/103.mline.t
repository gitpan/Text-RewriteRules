my $__XMLattrs = qr/(?:\s+[a-zA-Z0-9:-]+\s*=\s*(?: '[^']+' | "[^"]+" ))*/x;
my $__XMLempty = qr/<[a-zA-Z0-9:-]+$__XMLattrs\/>/x;
my $__XMLtree  = qr/(?<XML>
                      <(?<TAG>[a-zA-Z0-9:-]+)$__XMLattrs>
                        (?:  $__XMLempty  |  [^<]++  |  (?&XML) )*+
                      <\/(?&TAG)>
                  )/x;
my $__XMLinner = qr/(?:  [^<]++ | $__XMLempty | $__XMLtree )*+/x;
# -*- cperl -*-
use Test::More tests => 4;


sub first {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__27#
    MAIN: while($modified) {
      $modified = 0;
      if (m{a b c }x) {
        s{a b c }{cba}x;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(first("abc"),"cba");
is(first("a b c"), "a b c");


sub second {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__28#
    MAIN: while($modified) {
      $modified = 0;
      if (m{a
b
c
}x) {
        s{a
b
c
}{cba}x;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(second("abc"),"cba");
is(second("a b c"), "a b c");
