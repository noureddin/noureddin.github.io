#!/usr/bin/env perl
# vim: set fdm=marker :
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

### UTILS {{{1

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


### SOFTWARE {{{1

# ignore software (in `.software`) by part of its url, case-insensitive (may contain regex-metachars)
my @IGNORE = (
  '/gdl',        # no logo yot; needs a lot of updates; quite dormant
  '/lanbeeper',  # no logo yet; too basic; quite dormant
  '/epread',     # no logo yet; needs a lot of updates
  '/cuteview',   # needs a lot of updates
  '/irsaa',      # not published yet
);

my @software;
open my $s, '<', '.software';
my $i = 0;
while (<$s>) {
  if ($i % 4 == 0) {
    my ($has_app, $name,             $img_ext,          $ar,        $en) =
     m@^(/?)      ([a-zA-Z0-9_-]+)[.]([a-zA-Z0-9]+) [ ]+([^|]*) [|] (.*)$@x;
    $ar =~ s/\s*$//;
    $en =~ s/^\s*//;
    push @software, {
      src => "https://github.com/noureddin/$name/",  # repo
      app => $has_app ? "/$name/" : '',  # web app
      img => "etc/$name.$img_ext",
      # alt is $ar w/o any char followed by apostrophe, then &mdash + $en if found
      alt => ($ar =~ s/.'//gr).($en ? ' &mdash; '.$en : ''),
      ar  => $ar =~ s/'//gr,
      en  => $en,
    }
  }
  elsif ($i % 4 == 1) { $software[$#software]{ara} = ichomp }
  elsif ($i % 4 == 2) { $software[$#software]{eng} = ichomp }
  else { die "expected empty line in .software at line $i\n" unless $_ eq "\n" }
  ++$i;
}
close $s;

sub make_urls { my ($src, $src_txt, $app, $app_txt) = @_;
  return "<center>(".(
      join ' | ',
        ($app ? sprintf '<a href="%s">%s</a>', $app, $app_txt : ''),
        ($src ? sprintf '<a href="%s">%s</a>', $src, $src_txt : ''),
    ).")</center>";
  my $ret = '';
  if ($app) {
  }
}

my $software = join "", map {
  my $urls_ar = make_urls $_->{src} => 'مستودع الكود', $_->{app} => 'تطبيق الويب';
  my $urls_en = make_urls $_->{src} => 'Code Repo',    $_->{app} => 'Web App';
  my $desc_ar = sprintf '<p><b>%s:</b> %s</p>%s', $_->{ar} => $_->{ara} => $urls_ar;
  my $desc_en = $_->{en} && sprintf '<p><b>%s:</b> %s</p>%s', $_->{en} => $_->{eng} => $urls_en;
  qq[<img tabindex=0 src="$_->{img}" alt="$_->{alt}" width=72 height=72><!--
  --><section class=d><!--
    --><div lang=ar dir=rtl>$desc_ar</div><!--
    --><div lang=en dir=ltr>$desc_en</div><!--
  --></section><!--
  -->] =~ s/\s+/ /gr =~ s/<!--.*?-->//gr =~ s/\s*\Z//gr
} grep { $_->{src} !~ /@{[ join '|', @IGNORE ]}/i } @software;

$software .= q[
  <section class=d>
    <div lang=ar dir=rtl><p>
      قف على أي رمز بالأعلى لإظهار وصف تطبيقه ورابطه.
    </p></div>
    <div lang=en dir=ltr><p>
      Hover over any of the above logos to show its app's description and link.
    </p></div>
  </section>
] =~ s/\s+/ /gr =~ s/> />/gr =~ s/ </</gr =~ s/\A | \Z//r;


### WRITINGS {{{1

my $writings = slurp('../w/index.html')
  =~ s|.*<main>(.*?)</main>.*|$1|sr
  =~ s|<center><picture>.*?</picture></center>||gr
  =~ s|(</?h)2>|${1}3>|gr
  =~ s| href="|$&/w/|gr
  =~ s|(/section>)\n(<section)|$1$2|gr
  =~ s|\A\s*||gr
  =~ s|\s*\Z||gr
  ;


### STYLE {{{1

my $style = scalar qx[ deno run --quiet --allow-read npm:clean-css-cli etc/style.css ];


### OUTPUT {{{1

print minify_html(slurp '.index.html')
  =~ s|\Q{{style}}\E|$style|gr
  =~ s|\Q{{software}}\E|$software|gr
  =~ s|\Q{{writings}}\E|$writings|gr

