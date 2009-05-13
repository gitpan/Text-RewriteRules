my $__XMLattrs = qr/(?:\s+[a-zA-Z0-9:-]+\s*=\s*(?: '[^']+' | "[^"]+" ))*/x;
my $__XMLempty = qr/<[a-zA-Z0-9:-]+$__XMLattrs\/>/x;
my $__XMLtree  = qr/(?<XML>
                      <(?<TAG>[a-zA-Z0-9:-]+)$__XMLattrs>
                        (?:  $__XMLempty  |  [^<]++  |  (?&XML) )*+
                      <\/(?&TAG)>
                  )/x;
my $__XMLinner = qr/(?:  [^<]++ | $__XMLempty | $__XMLtree )*+/x;
# -*- cperl -*-
use Test::More tests => 7;


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


my $in = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in2 = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";

is(first($in),"ola XML ola");
is(first($in2),"ola XML ola XML ola");

is(Xsecond($in),"ola <a hmm =\"hmm\"><b>XML<c>o</c></b></a> ola");
is(Ysecond($in),"ola <a hmm =\"hmm\"><b><d zbr='foo'/>XML</b></a> ola");
is(Zsecond($in),"ola <a hmm =\"hmm\">XML</a> ola");
is(Zsecond($in2),"ola <a hmm =\"hmm\">XML</a> ola <a hmm =\"hmm\">XML</a> ola");

is(third($in),"ola a ola");

