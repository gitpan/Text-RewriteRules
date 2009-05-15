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
use Test::More tests => 17;


my $lexer_input = "";
sub lexer_init {
  $lexer_input = shift;
  return 1;
}

sub lexer {
  return undef if not defined $lexer_input;
  for ($lexer_input) {
      if (m{^foo}g) {
        s{foo\G}{};
        return "zbr"
      }
      if (m{^bar}g) {
        s{bar\G}{};
        return "ugh"
      }
  }
  return undef;
}


is(lexer(),undef);

lexer_init("foobar");
is(lexer(),"zbr");
is(lexer(),"ugh");
is(lexer(),undef);

# (4 tests above)---------------

my $lex_input = "";
sub lex_init {
  $lex_input = shift;
  return 1;
}

sub lex {
  return undef if not defined $lex_input;
  for ($lex_input) {
      if (m{^(\d+)}g) {
        s{(\d+)\G}{};
        return ["INT",$1];
      }
      if (m{^([A-Z]+)}g) {
        s{([A-Z]+)\G}{};
        return ["STR",$1];
      }
  }
  return undef;
}


is(lex(),undef);
lex_init("ID25");
is_deeply(lex(),["STR","ID"]);
is_deeply(lex(),["INT", 25]);
is(lex(),undef);

# (8 tests above)-----------------

my $yylex_input = "";
sub yylex_init {
  $yylex_input = shift;
  return 1;
}

sub yylex {
  return undef if not defined $yylex_input;
  for ($yylex_input) {
      if (m{^IF}g) {
        s{IF\G}{};
        return ["IF","IF"];
      }
      if (m{^(\w+)}g) {
        s{(\w+)\G}{};
        return ["ID",$1];
      }
      if (m{^\s+}gi) {
        s{\s+\G}{}i;
        return yylex();
      }
  }
  return undef;
}


is(yylex(),undef);
yylex_init("  IF XPTO");
is_deeply(yylex(),["IF","IF"]);
is_deeply(yylex(),["ID","XPTO"]);
is(yylex(),undef);

# (12 tests above)----------------

my $foo_input = "";
sub foo_init {
  $foo_input = shift;
  return 1;
}

sub foo {
  return undef if not defined $foo_input;
  for ($foo_input) {
      if (m{^IF}gx) {
        s{IF\G}{}x;
        return ("IF","IF");
      }
      if (m{^(\w+)}gx) {
        s{(\w+)\G}{}x;
        return ("ID",$1);
      }
      if (m{^\s+}gix) {
        s{\s+\G}{}ix;
        return foo();
      }
      if (m{^$}) {
         $foo_input = undef;
         return ('',undef);
      }
  }
  return undef;
}


=head Fix Highlight
=cut

is(foo(),undef);
foo_init("  IF XPTO");
is_deeply([foo()],["IF","IF"]);
is_deeply([foo()],["ID","XPTO"]);
is_deeply([foo()],['',undef]);
is(foo(),undef);