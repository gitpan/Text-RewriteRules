package Text::RewriteRules;

use Filter::Simple;

use warnings;
use strict;

=head1 NAME

Text::RewriteRules - A system to rewrite text using regexp-based rules

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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
  my ($name, $rules) = @_;
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

  ##---
  my @rules = split /\n/, $rules;
  for my $rule (@rules) {
    if ($rule =~ m/(.*)==>(.*)!!(.*)/) {
      $code .= "      while (m{\${_M}$1}g) {\n";
      $code .= "        if ($3) {\n";
      $code .= "          s{\${_M}$1\\G}{$2\${_M}}\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*)=e(?:val)?=>(.*)!!(.*)/) {
      $code .= "      while (m{\${_M}$1}g) {\n";
      $code .= "        if ($3) {\n";
      $code .= "          s{\${_M}$1\\G}{$2\${_M}}e\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*)==>(.*)/) {
      $code .= "      if (m{\${_M}$1}) {\n";
      $code .= "        s{\${_M}$1}{$2\${_M}};\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*)=e(?:val)?=>(.*)/) {
      $code .= "      if (m{\${_M}$1}) {\n";
      $code .= "        s{\${_M}$1}{($2).\"\$_M\"}e;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";
    }
  }
  ##---

  $code .= "    }\n";
  $code .= "    s/\$_M\$//;\n";
  $code .= "  }\n";
  $code .= "  return \$p;\n";
  $code .= "}\n";

  $code;
}

sub _rules {
  my ($name, $rules) = @_;
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

  my @rules = split /\n/, $rules;
  for my $rule (@rules) {
    if($rule =~ m/(.*)==>(.*)!!(.*)/) {
      $code .= "      while (m{$1}g) {\n";
      $code .= "        if ($3) {\n";
      $code .= "          s{$1\\G}{$2};\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif($rule =~ m/(.*)=e(?:val)?=>(.*)!!(.*)/) {
      $code .= "      while (m{$1}g) {\n";
      $code .= "        if ($3) {\n";
      $code .= "          s{$1\\G}{$2}e;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*)==>(.*)/) {
      $code .= "      if (m{$1}) {\n";
      $code .= "        s{$1}{$2};\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*)=e(?:val)?=>(.*)/) {
      $code .= "      if (m{$1}) {\n";
      $code .= "        s{$1}{$2}e;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif($rule =~ m/=b(?:egin)?=>(.*)/) {
      my $ac = $1;
      $code =~ s/(#__$count#\n)/$ac;\n$1/;

    } elsif($rule =~ m/(.*)=l(ast)?=>/) {
      $code .= "      if (m{$1}) {\n";
      $code .= "        last\n";
      $code .= "      }\n";
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

  s!^RULES (\w+)\n((?:.|\n)*?)^ENDRULES! _rules($1,$2)!gem;
  s!^MRULES (\w+)\n((?:.|\n)*?)^ENDRULES!_mrules($1,$2)!gem;

  print STDERR "AFTER>>>>\n$_\n<<<<\n" if $DEBUG;

  $_
};

=head1 TUTORIAL

Under development

=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

José João Almeida, C<< <jjoao@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-rewrite@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Damian Conway for Filter::Simple

=head1 COPYRIGHT & LICENSE

Copyright 2004 Alberto Simões and José João Almeida, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::RewriteRules
