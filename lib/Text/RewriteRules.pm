package Text::RewriteRules;

use Data::Dumper;
use Filter::Simple;

use warnings;
use strict;

=head1 NAME

Text::RewriteRules - A system to rewrite text using regexp-based rules

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    use Text::RewriteRules;

    RULES email
    .==> DOT 
    @==> AT 
    ENDRULES

    email("ambs@cpan.org") # returns ambs AT cpan DOT org

=head1 ABSTRACT

This module uses a simplified syntax for regexp-based rules for
rewriting text. You define a set of rules, and the system applies them
until no more rule can be applied.

=head1 DESCRIPTION

A lot of computer science problems can be solved using rewriting
rules.

Rewriting rules consist of mainly two parts: a regexp (LHS: Left Hand
Side) that is matched with the text, and the string to use to
substitute the content matched with the regexp (RHS: Right Hand Side).

Now, why don't use a simple substitute? Because we want to define a
set of rules and match them again and again, until no more regexp of
the LHS matches.

A point of discussion is the syntax to define this system. A brief
discussion shown that some users would prefer a function to receive an
hash with the rules, some other, prefer some syntax sugar.

The approach used is the last: we use C<Filter::Simple> such that we
can add a specific non-perl syntax inside the Perl script. This
improves legibility of big rewriting rules sytems.

This documentation is divided in two parts: first we will see the
reference of the module. Kind of, what it does, with a brief
explanation. Follows a tutorial which will be growing through time and
releases.

=head1 SYNTAX REFERENCE

Note: most of the examples are very stupid, but that is the easiest
way to explain the basic syntax.

The basic syntax for the rewrite rules is a block, started by the
keyword C<RULES> and ended by the C<ENDRULES>. Everything between
them is handled by the module and interpreted as rules or comments.

The C<RULES> keyword can handle a set of flags (we will see that
later), and requires a name for the rule-set. This name will be used
to define a function for that rewriting system.

   RULES functioname
    ...
   ENDRULES

The function is defined in the main namespace where the C<RULES>
block appears.

In this block, each line can be a comment (Perl style), an empty line
or a rule.

=head2 Basic Rule

A basic rule is a simple substitution:

  RULES foobar
  foo==>bar
  ENDRULES

The arrow C<==E<gt>> is used as delimiter. At its left is the regexp
to match, at the right side, the substitution. So, the previous block
defines a C<foobar> function that substitutes all C<foo> by
C<bar>.

Although this can seems similar to a global substitution, it is
not. With a global substitution you can't do an endless loop. With
this module it is very simple. I know you will get the idea.

You can use the syntax of Perl both on the left and right hand side of
the rule, including C<$1...>.

=head2 Execution Rule

If the Perl substitution supports execution, why not to support it,
also? So, you got the idea. Here is an example:

  RULES foo
  (\d+)b=e=>'b' x $1
  (\d+)a=eval=>'a' x ($1*2)
  ENDRULES

So, for any number followed by a C<b>, we replace by that number of
C<b's>. For each number followed by an C<a>, we replace them by twice
that number of C<a's>.

Also, you mean evaluation using an C<e> or C<eval> inside the arrow. I
should remind you can mix all these rules together in the same
rewriting system.

=head2 Conditional Rule

On some cases we want to perform a susbtitution if the pattern matches
B<and> a set of conditions about that pattern (or not) are true.

For that, we use a three part rule. We have the common rule plus the
condition part, separated from the rule by C<!!>. These conditional
rules can be applied both for basic and exeuction rules.

  RULES translate
  ([[:alpha:]]+)=e=>$dic{$1}!! exists($dic{$1})
  ENDRULES

The previous example would translate all words that exist on the
dictionary.

=head2 Begin Rule

Sometimes it is useful to change something on the string before
starting to apply the rules. For that, there is a special rule named
C<begin> (or C<b> for abbreviate) just with a RHS. This RHS is Perl
code. Any Perl code. If you want to modify the string, use C<$_>.

  RULES foo
  =b=> $_.=" END"
  ENDRULES

=head2 Last Rule

As you use C<last> on Perl to skip the remaining code on a loop, you
can also call a C<last> (or C<l>) rule when a specific pattern
matches.

Like the C<begin> rule with only a RHS, the C<last> rule has only a
LHS:

  RULES foo
  foobar=l=>
  ENDRULES

This way, the rules iterate until the string matches with C<foobar>.

=cut

my $DEBUG = 0;

our $count = 0;

sub _mrules {
  my ($conf, $name, $rules) = @_;
  ++$count;

  chomp($rules);

  my $code = "sub $name {\n";
  $code .= "  my \$p = shift;\n";
  $code .= "  my \$_M = \"\\x01\";\n";
  $code .= "  for (\$p) {\n";
  $code .= "    my \$modified = 1;\n";
  $code .= "    \$_ = \$_M.\$_;\n";
  $code .= "    #__$count#\n";
  $code .= "    MAIN: while (\$modified) {\n";
  $code .= "      \$modified = 0;\n";

  my $ICASE = "";

  ##---
  my @rules = split /\n/, $rules;
  for my $rule (@rules) {
    if ($rule =~ m/(.*?)(=i?=>)(.*)!!(.*)/) {
      my ($ant,$con,$cond) = ($1,$3,$4);
      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      while (m{\${_M}$ant}g$ICASE) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{\${_M}$ant\\G}{$con\${_M}}$ICASE;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)!!(.*)/) {
      my ($ant,$con,$cond) = ($1,$3,$4);
      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      while (m{\${_M}$ant}g$ICASE) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{\${_M}$ant\\G}{eval{$con}.\${_M}}e$ICASE;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=i?=>)(.*)/) {
      my ($ant,$con) = ($1,$3);
      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{\${_M}$ant}$ICASE) {\n";
      $code .= "        s{\${_M}$ant}{$con\${_M}}$ICASE;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)/) {
      my ($ant,$con) = ($1,$3);
      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{\${_M}$ant}$ICASE) {\n";
      $code .= "        s{\${_M}$ant}{eval{$con}.\"\$_M\"}e$ICASE;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";
    } else {
      warn "Unknown rule: $rule\n" unless $rule =~ m!^\s*(#|$)!;
    }
  }
  ##---


  # Make it walk...
  $code .= "      if (m{\${_M}.}) {\n";
  $code .= "        s{\${_M}(.)}{\$1\${_M}};\n";
  $code .= "        \$modified = 1;\n";
  $code .= "        next\n";
  $code .= "      }\n";



  $code .= "    }\n";
  $code .= "    s/\$_M//;\n";
  $code .= "  }\n";
  $code .= "  return \$p;\n";
  $code .= "}\n";

  $code;
}

sub _rules {
  my ($conf,$name, $rules) = @_;
  ++$count;

  chomp($rules);

  my $code = "sub $name {\n";
  $code .= "  my \$p = shift;\n";
  $code .= "  for (\$p) {\n";
  $code .= "    my \$modified = 1;\n";
  $code .= "    #__$count#\n";
  $code .= "    MAIN: while(\$modified) {\n";
  $code .= "      print STDERR \$_;\n" if $DEBUG > 1;
  $code .= "      \$modified = 0;\n";

  ##---

  my $DICASE = exists($conf->{i})?"i":"";
  my $DX = exists($conf->{x})?"x":"";

  my @rules;
  if ($DX eq "x") {
    @rules = split /\n\n/, $rules;
  } else {
    @rules = split /\n/, $rules;
  }

  for my $rule (@rules) {

    my $ICASE = $DICASE;

    if($rule =~ m/(.*?)(=i?=>)(.*)!!(.*)/s) {
      my ($ant,$con,$cond) = ($1,$3,$4);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      while (m{$ant}g$ICASE$DX) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{$ant\\G}{$con}$ICASE$DX;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)!!(.*)/s) {
      my ($ant,$con,$cond) = ($1,$3,$4);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      while (m{$ant}g$ICASE$DX) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{$ant\\G}{$con}e${ICASE}${DX};\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=i?=>)(.*)/s) {
      my ($ant,$con) = ($1,$3);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
      $code .= "        s{$ant}{$con}$ICASE$DX;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)/s) {
      my ($ant,$con) = ($1,$3);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
      $code .= "        s{$ant}{$con}e$ICASE$DX;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif($rule =~ m/=b(?:egin)?=>(.*)/s) {

      my $ac = $1;
      $code =~ s/(#__$count#\n)/$ac;\n$1/;

    } elsif($rule =~ m/(.*?)(=(i=)?l(ast)?=>)/s) {
      my ($ant) = ($1);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
      $code .= "        last\n";
      $code .= "      }\n";
    } else {
      warn "Unknown rule: $rule\n" unless $rule =~ m!^\s*(#|$)!;
    }
  }

  ##---

  $code .= "    }\n";
  $code .= "  }\n";
  $code .= "  return \$p;\n";
  $code .= "}\n";

  $code;
}

FILTER {
  return if m!^(\s|\n)*$!;

  print STDERR "BEFORE>>>>\n$_\n<<<<\n" if $DEBUG;


  s!^MRULES (\w+)\n((?:.|\n)*?)^ENDRULES!_mrules({}, $1,$2)!gem;

  s{^RULES((?:\/\w+)?) (\w+)\n((?:.|\n)*?)^ENDRULES}{
     my ($a,$b,$c) = ($1,$2,$3);
     my $conf = {map {($_=>$_)} split //,$a};
     if (exists($conf->{'m'})) {
       _mrules($conf,$b,$c)
     } else {
       _rules($conf,$b,$c)
     }
   }gem;



  print STDERR "AFTER>>>>\n$_\n<<<<\n" if $DEBUG;

  $_
};

=head1 TUTORIAL

At the moment, just a set of commented examples.

=head1 Conversion between numbers and words

Yes, you can use L<Lingua::PT::Nums2Words> and similar (for other
languages). Meanwhile, before it existed we needed to write such a
conversion tool.

Here I present a subset of the rules (for numbers bellow 1000). The
generated text is Portuguese but I think you can get the idea. I'll
try to create a version for English very soon.

You can check the full code on the samples directory (file
C<num2words>).

  use Text::RewriteRules;

  RULES num2words
  100==>cem 
  1(\d\d)==>cento e $1 
  0(\d\d)==>$1
  200==>duzentos 
  300==>trezentos 
  400==>quatrocentos 
  500==>quinhentos 
  600==>seiscentos 
  700==>setecentos 
  800==>oitocentos 
  900==>novecentos 
  (\d)(\d\d)==>${1}00 e $2

  10==>dez 
  11==>onze 
  12==>doze 
  13==>treze 
  14==>catorze 
  15==>quinze 
  16==>dezasseis 
  17==>dezassete 
  18==>dezoito 
  19==>dezanove 
  20==>vinte 
  30==>trinta 
  40==>quarenta 
  50==>cinquenta 
  60==>sessenta 
  70==>setenta 
  80==>oitenta 
  90==>noventa 
  0(\d)==>$1
  (\d)(\d)==>${1}0 e $2

  1==>um 
  2==>dois 
  3==>tr�s 
  4==>quatro 
  5==>cinco 
  6==>seis 
  7==>sete 
  8==>oito 
  9==>nove 
  0$==>zero 
  0==> 
    ==> 
   ,==>,
  ENDRULES

  num2words(123); # returnes "cento e vinte e tr�s"

=head1 AUTHOR

Alberto Sim�es, C<< <ambs@cpan.org> >>

Jos� Jo�o Almeida, C<< <jjoao@cpan.org> >>

=head1 BUGS

We know documentation is missing and you all want to use this module.
In fact we are using it a lot, what explains why we don't have the
time to write documentation.

Please report any bugs or feature requests to
C<bug-text-rewrite@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Damian Conway for Filter::Simple

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Alberto Sim�es and Jos� Jo�o Almeida, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::RewriteRules
