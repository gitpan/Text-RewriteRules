package Text::RewriteRules;

use Data::Dumper;
use Filter::Simple;

use warnings;
use strict;

=head1 NAME

Text::RewriteRules - A system to rewrite text using regexp-based rules

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Text::RewriteRules;

    RULES email
    .==> DOT 
    @==> AT 
    ENDRULES

    email("ambs@cpan.org") # returns ambs AT cpan DOT org

=cut

my $DEBUG = 0;

our $count = 0;

sub _mrules {
  my ($conf, $name, $rules) = @_;
  ++$count;

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
      $code .= "          s{\${_M}$ant\\G}{$con\${_M}}e$ICASE;\n";
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
      $code .= "        s{\${_M}$ant}{($con).\"\$_M\"}e$ICASE;\n";
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
  $code .= "    s/\$_M\$//;\n";
  $code .= "  }\n";
  $code .= "  return \$p;\n";
  $code .= "}\n";

  $code;
}

sub _rules {
  my ($conf,$name, $rules) = @_;
  ++$count;

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

  my @rules = split /\n/, $rules;

  for my $rule (@rules) {

    my $ICASE = $DICASE;

    if($rule =~ m/(.*?)(=i?=>)(.*)!!(.*)/) {
      my ($ant,$con,$cond) = ($1,$3,$4);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      while (m{$ant}g$ICASE) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{$ant\\G}{$con}$ICASE;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)!!(.*)/) {
      my ($ant,$con,$cond) = ($1,$3,$4);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      while (m{$ant}g$ICASE) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{$ant\\G}{$con}e${ICASE};\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=i?=>)(.*)/) {
      my ($ant,$con) = ($1,$3);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{$ant}$ICASE) {\n";
      $code .= "        s{$ant}{$con}$ICASE;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)/) {
      my ($ant,$con) = ($1,$3);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{$ant}$ICASE) {\n";
      $code .= "        s{$ant}{$con}e$ICASE;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif($rule =~ m/=b(?:egin)?=>(.*)/) {

      my $ac = $1;
      $code =~ s/(#__$count#\n)/$ac;\n$1/;

    } elsif($rule =~ m/(.*?)(=(i=)?l(ast)?=>)/) {
      my ($ant) = ($1);

      $ICASE = "i" if $2 =~ m!i!;

      $code .= "      if (m{$ant}$ICASE) {\n";
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
  3==>três 
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

  num2words(123); # returnes "cento e vinte e três"

=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

José João Almeida, C<< <jjoao@cpan.org> >>

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

Copyright 2004-2005 Alberto Simões and José João Almeida, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::RewriteRules
