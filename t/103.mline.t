my $__XMLattrs = qr/(?:\s+[a-zA-Z0-9:-]+\s*=\s*(?: '[^']+' | "[^"]+" ))*/x;
my $__XMLempty = qr/<[a-zA-Z0-9:-]+$__XMLattrs\/>/x;
my $__XMLtree  = qr/$__XMLempty |
                  (?<XML>
                      <(?<TAG>[a-zA-Z0-9:-]+)$__XMLattrs>
                        (?:  $__XMLempty  |  [^<]++  |  (?&XML) )*+
                      <\/\k<TAG>>
                  )/x;
my $__XMLinner = qr/(?:  [^<]++ | $__XMLempty | $__XMLtree )*+/x;

my $__CBB = qr{(\{(?:[^\{\}]++|(?-1))*+\})}sx; ## curly brackets block { ... }  FIXME!!!
my $__BB  = qr{(\[(?:[^\[\]]++|(?-1))*+\])}sx; ##       brackets block [ ... ]  FIXME!!!
my $__PB  = qr{(\((?:[^\(\)]++|(?-1))*+\))}sx; ##     parentesis block ( ... )  FIXME!!!
my $__TEXENV  = qr{\\begin\{(\w+)\}(.*?)\\end\{\1\}}s;                 ## FIXME
my $__TEXENV1 = qr{\\begin\{(\w+)\}($__BB?)($__CBB)(.*?)\\end\{\1\}}s; ## FIXME


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
