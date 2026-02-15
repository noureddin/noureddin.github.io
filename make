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
  '/ysmu',
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
    my $alt_ar = $ar =~ s/.'//gr;
    my $web_ar = $ar =~ s/'//gr,
    my $alt_en = $en ? ($en =~ s,//.*,,r) : '';
    my $web_en = $en ? ($en =~ s,.*//,,r) : '';
    push @software, {
      src => "https://github.com/noureddin/$name/",  # repo
      app => $has_app ? "/$name/" : '',  # web app
      img => "etc/$name.$img_ext",
      # alt is $ar w/o any char followed by apostrophe, then &mdash + $en if found
      alt => $alt_ar.($alt_en ? ' &mdash; '.$alt_en : ''),
      ar  => $web_ar,
      en  => $web_en,
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
  my $urls_ar = make_urls($_->{src} => 'المصدر~البرمجي', $_->{app} => 'تطبيق~الوب') =~ s/~/&nbsp;/gr;
  my $urls_en = make_urls($_->{src} => 'Source~Code',    $_->{app} => 'Web~App')    =~ s/~/&nbsp;/gr;
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

my $writings = sprintf "<ul>%s</ul>",
  (join "", (slurp('../w/index.html') =~ m|<h2>.*?</h2>.*?<div class="time">.*?</div>|g))
  =~ s|<h2>|<li>|gr
  =~ s|(?<=</h2>).*?<div (class="time">)(.*?</span>).*?</div>|<span $1 &mdash; $2</span></li>|gr
  # remove all content, except a>h2 and the first part of div.time (updating date if any, otherwise publishing date)
  # and add an em-dash before the time, and put into a list item; next: make urls relative to /w/, and remove the images.
  =~ s| href="|$&/w/|gr
  =~ s|<center><picture>.*?</picture></center>||gr
  ;


### STYLE {{{1

my $style = scalar qx[ deno run --quiet --allow-read --allow-env=HTTP_PROXY,http_proxy npm:clean-css-cli etc/style.css ];

### SCRIPT {{{1

my $script = <<'END_OF_TEXT';
const w=()=>document.body.style.setProperty('--ww',(window.innerWidth||document.documentElement.clientWidth)+'px')
onresize=w
w()

if (!(location.search + location.hash).split(/[?&#]/).includes('nostats')) {
  window.goatcounter = { path: location.href.replace(/[?#].*/,''), allow_frame: true }
  // privacy-friendly statistics, no tracking of personal data, no need for GDPR consent; see goatcounter.com
  const el = document.createElement('script')
  el.dataset.goatcounter = 'https://noureddin.goatcounter.com/count'
  el.async = true
  el.src = 'count.min.js'
  document.body.append(el)
}

END_OF_TEXT

# count.min.js is generated from the official count.js file
#  ( see https://www.goatcounter.com/help/countjs-host )
# by this command:
#   deno run --allow-read --allow-env=UGLIFY_BUG_REPORT npm:uglify-js --compress < count.js > count.min.js

### OUTPUT {{{1

print minify_html(slurp '.index.html')
  =~ s|\Q{{style}}\E|$style|gr
  =~ s|\Q{{script}}\E|$script|gr
  =~ s|\Q{{software}}\E|$software|gr
  =~ s|\Q{{writings}}\E|$writings|gr

