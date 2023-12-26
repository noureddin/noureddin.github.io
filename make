#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];
sub ichomp(_) { my $x = $_[0]; chomp $x; return $x }  # in-place chomp
sub slurp(_) { local $/; open my $f, '<', $_[0]; return scalar <$f> }

# ignore software (in `.software`) by part of its url, case-insensitive (may contain regex-metachars)
my @IGNORE = (
  '/gdl',        # no logo yot; needs a lot of updates; quiet dormant
  '/lanbeeper',  # no logo yet; too basic; quiet dormant
  '/epread',     # no logo yet; needs a lot of updates
  '/cuteview',   # needs a lot of updates
  '/irsaa',      # not published yet
);

my @software;
open my $s, '<', '.software';
my $i = 0;
while (<$s>) {
  if ($i % 6 == 0) { push @software, { url => ichomp } }
  elsif ($i % 6 == 1) { $software[$#software]{img} = ichomp }
  elsif ($i % 6 == 2) { $software[$#software]{alt} = ichomp }
  elsif ($i % 6 == 3) { $software[$#software]{ara} = ichomp }
  elsif ($i % 6 == 4) { $software[$#software]{eng} = ichomp }
  else { die "expected empty line in .software at line $i\n" unless $_ eq "\n" }
  ++$i;
}
close $s;

my $software = join "\n", map {
  qq[<a href="$_->{url}"><img src="$_->{img}" alt="$_->{alt}" width="72" height="72"></a>
    <section class="software-description">
      <div lang="ar" dir="rtl">$_->{ara}</div>
      <div lang="en" dir="ltr">$_->{eng}</div>
    </section>
  ] =~ s/\s+/ /gr =~ s/> </></gr
} grep { $_->{url} !~ /@{[ join '|', @IGNORE ]}/i } @software;

$software .= q[
  <section class="software-description">
    <div lang="ar" dir="rtl"><p>
      قف على أي من الرموز التي بالأعلى لإظهار وصف تطبيقها،
      أو&nbsp;انقر عليها للانتقال إلى صفحته.
    </p></div>
    <div lang="en" dir="ltr"><p>
      Hover over any of the above logos to show its app's description,
      or&nbsp;click on it to go to its page.
    </p></div>
  </section>
] =~ s/\s+/ /gr =~ s/<p> /<p>/gr =~ s| </p>|</p>|gr;

my $writings = slurp('../w/index.html')
  =~ s|.*<main>(.*?)</main>.*|$1|sr
  =~ s|<center><picture>.*?</picture></center>||gr
  =~ s|(</?h)2>|${1}3>|gr
  =~ s| href="|$&/w/|gr
  ;

open my $f, '<', '.index.html';
while (<$f>) {
  s|\Q{{software}}\E|$software|g;
  s|\Q{{writings}}\E|$writings|g;
  print;
}
close $f;

