#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

### UTILS

sub ichomp(_) { my $x = $_[0]; chomp $x; return $x }  # in-place chomp
sub slurp(_) { local $/; open my $f, '<', $_[0]; return scalar <$f> }

# shared between github.com/noureddin/{kbt,recite} and this
sub minify_html { my $t = shift;
    ## remove comments
    $t =~ s|<!--.*?-->||gs;
    ## collapse spaces
    $t =~ s|\s+| |g;
    ## remove horizontal spaces around punctuation
    $t =~ s|> <|><|g;
    $t =~ s/(<(?:script|style)>) /$1/g;
    $t =~ s/ (<\/(?:script|style)>)/$1/g;
    ## old:
    # $t =~ s|(?<=\W) (?=\W)||g;
    # $t =~ s|(?<=[^\w"]) (?=\w)||g; # don't remove the space between html attributes
    # $t =~ s| (?=\W)||g;
    ## remove leading and trailing spaces
    $t =~ s|\A\s+||g;
    $t =~ s|\s+\Z||g;
    ## for debugging
    # $t =~ s| <|█<|g;
    # $t =~ s|> |>█|g;
    ## unquote attribute values if allowable (I use only double-quotes in html)
    ## https://html.spec.whatwg.org/multipage/syntax.html#unquoted
    $t =~ s|(\b\w+)="([^\s"'`<>=]+)"|$1=$2|g;
    $t =~ s|(\b\w+)=""|$1|g;
    return $t;
}


### SOFTWARE

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
  qq[<a href="$_->{url}"><img src="$_->{img}" alt="$_->{alt}" width=72 height=72></a><!--
  --><section class=d><!--
    --><div lang=ar dir=rtl>$_->{ara}</div><!--
    --><div lang=en dir=ltr>$_->{eng}</div><!--
  --></section><!--
  -->] =~ s/\s+/ /gr =~ s/<!--.*?-->//gr =~ s/\s*\Z//gr
} grep { $_->{url} !~ /@{[ join '|', @IGNORE ]}/i } @software;

$software .= q[
  <section class=d>
    <div lang=ar dir=rtl><p>
      قف على أي من الرموز التي بالأعلى لإظهار وصف تطبيقها،
      أو&nbsp;انقر عليها للانتقال إلى صفحته.
    </p></div>
    <div lang=en dir=ltr><p>
      Hover over any of the above logos to show its app's description,
      or&nbsp;click on it to go to its page.
    </p></div>
  </section>
] =~ s/\s+/ /gr =~ s/> />/gr =~ s/ </</gr;


### WRITINGS

my $writings = slurp('../w/index.html')
  =~ s|.*<main>(.*?)</main>.*|$1|sr
  =~ s|<center><picture>.*?</picture></center>||gr
  =~ s|(</?h)2>|${1}3>|gr
  =~ s| href="|$&/w/|gr
  ;


### STYLE

my $style = scalar qx[ deno run --quiet --allow-read npm:clean-css-cli etc/style.css ];


### OUTPUT

print minify_html(slurp '.index.html')
  =~ s|\Q{{style}}\E|$style|gr
  =~ s|\Q{{software}}\E|$software|gr
  =~ s|\Q{{writings}}\E|$writings|gr

