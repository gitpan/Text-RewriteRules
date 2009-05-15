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
use Test::More tests => 9;


## Replace
sub first {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__18#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{bb${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(first("bar"),"bba");



## Replace (ignore case)
sub ifirst {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__25#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:b)}i) {
        s{${_M}(?:b)}{bb${_M}}i;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}i) {
        s{${_M}(?:r)}{${_M}}i;
        $modified = 1;
        next
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(ifirst("Bar"),"bba");



## Eval
sub second {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__19#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{eval{'b' x 2}."$_M"}e;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(second("bar"),"bba");



## Eval with ignore case
sub isecond {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__20#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:(b))}i) {
        s{${_M}(?:(b))}{eval{$1 x 2}."$_M"}ei;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}i) {
        s{${_M}(?:r)}{${_M}}i;
        $modified = 1;
        next
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(isecond("Bar"),"BBa");



sub third {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__21#
    MAIN: while ($modified) {
      $modified = 0;
      while (m{${_M}(?:a)}g) {
        if (1) {
          s{${_M}(?:a)\G}{b${_M}};
          $modified = 1;
          next MAIN
        }
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(third("bab"),"bbb");


## use of flag instead of MRULES
sub fourth {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__26#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{bb${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(fourth("bar"),"bba");

## Eval
sub fifth {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__22#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{eval{$a = log(2); $a = sin($a);'b' x 2}."$_M"}e;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(fifth("bar"),"bba");

## Simple Last 
sub sixth {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__23#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:bar)}) {
        s{${_M}(?:bar)}{ugh${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:foo)}) {
        s{${_M}}{};
        last
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(sixth("barfoobar"),"ughfoobar");

## Last with condition
sub seventh {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__24#
    MAIN: while ($modified) {
      $modified = 0;
      if (m{${_M}(?:bar)}) {
        s{${_M}(?:bar)}{ugh${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:f(o+))}) {
        if (length($1)>2) {
          s{${_M}}{};
          last
        }
      }
      if (m{${_M}.}) {
        s{${_M}(.)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(seventh("barfoobarfooobar"),"ughfooughfooobar");
