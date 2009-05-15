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
use Test::More tests => 8;


sub first {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__33#
    MAIN: while($modified) {
      $modified = 0;
      if (m{$__XMLtree}) {
        s{$__XMLtree}{XML};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Xsecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__34#
    MAIN: while($modified) {
      $modified = 0;
      if (m{<d$__XMLattrs(?:/>|>$__XMLinner</d>)}) {
        s{<d$__XMLattrs(?:/>|>$__XMLinner</d>)}{XML};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Ysecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__35#
    MAIN: while($modified) {
      $modified = 0;
      if (m{<c$__XMLattrs(?:/>|>$__XMLinner</c>)}) {
        s{<c$__XMLattrs(?:/>|>$__XMLinner</c>)}{XML};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Zsecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__36#
    MAIN: while($modified) {
      $modified = 0;
      if (m{<b$__XMLattrs(?:/>|>$__XMLinner</b>)}) {
        s{<b$__XMLattrs(?:/>|>$__XMLinner</b>)}{XML};
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
    #__37#
    MAIN: while($modified) {
      $modified = 0;
      if (m{$__XMLtree}) {
        s{$__XMLtree}{$+{TAG}}e;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


my $in = "<a><b></a></b> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in2 = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in3 = "<foo hmm=\"bar\"/>";

is(first($in),"<a><b></a></b> ola XML ola");
is(first($in2),"ola XML ola XML ola");
is(first($in3), "XML");

is(Xsecond($in),"<a><b></a></b> ola <a hmm =\"hmm\"><b>XML<c>o</c></b></a> ola");
is(Ysecond($in),"<a><b></a></b> ola <a hmm =\"hmm\"><b><d zbr='foo'/>XML</b></a> ola");
is(Zsecond($in),"<a><b></a></b> ola <a hmm =\"hmm\">XML</a> ola");
is(Zsecond($in2),"ola <a hmm =\"hmm\">XML</a> ola <a hmm =\"hmm\">XML</a> ola");

is(third($in),"<a><b></a></b> ola a ola");


