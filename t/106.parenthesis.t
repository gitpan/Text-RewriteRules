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
use Test::More tests => 6;


sub first {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__38#
    MAIN: while($modified) {
      $modified = 0;
      if (m{$__PB}) {
        s{$__PB}{+};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub second {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__39#
    MAIN: while($modified) {
      $modified = 0;
      if (m{$__BB}) {
        s{$__BB}{*};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub third {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__40#
    MAIN: while($modified) {
      $modified = 0;
      if (m{$__CBB}) {
        s{$__CBB}{#};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


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

