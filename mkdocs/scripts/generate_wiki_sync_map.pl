#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Encode qw(decode);

my $repo_root = '.';
my $default_source = $ENV{SOURCE_ROOT} // $repo_root;
my $default_out = $ENV{WIKI_SYNC_MAP_FILE} // "$repo_root/mkdocs/scripts/wiki_sync_map.tsv";
my $source_root = $ARGV[0] // $default_source;
my $out_file = $ARGV[1] // $default_out;

-d $source_root or die "Missing source root: $source_root\n";

sub strip_order_prefix {
  my ($s) = @_;
  return '' unless defined $s;
  $s =~ s/^\d+_+//;
  return $s;
}

sub slugify {
  my ($s) = @_;
  $s = strip_order_prefix($s);
  $s = lc $s;
  $s =~ s/&/and/g;
  $s =~ s/[^a-z0-9]+/-/g;
  $s =~ s/^-+|-+$//g;
  $s =~ s/-{2,}/-/g;
  return $s;
}

sub split_segments {
  my ($stem) = @_;
  my @parts = split /-(?:\p{Pd}|:|-)-/u, $stem;
  @parts = grep { defined($_) && $_ !~ /^\s*$/ } @parts;
  return @parts;
}

sub join_slug {
  my (@parts) = @_;
  @parts = grep { defined($_) && length($_) } @parts;
  return join('-', @parts);
}

sub classify_additional_setup {
  my ($page) = @_;
  return 'backup' if $page =~ /(backup|restore|database)/;
  return 'moving-servers' if $page =~ /(migrate|replace|adding-a-game-server)/;
  return 'additional-installs';
}

sub parse_segment_for_sort {
  my ($seg) = @_;
  my ($has_order, $order, $name) = (0, 0, $seg);

  if ($seg =~ /^(\d+)_+(.+)$/) {
    $has_order = 1;
    $order = $1 + 0;
    $name = $2;
  }

  my $slug = slugify($name);
  return ($has_order, $order, $slug);
}

sub cmp_files {
  my ($file_a, $file_b) = @_;

  my $a_stem = $file_a;
  $a_stem =~ s/\.md$//;
  my $b_stem = $file_b;
  $b_stem =~ s/\.md$//;

  my @a_seg = split_segments($a_stem);
  my @b_seg = split_segments($b_stem);

  my $max = @a_seg > @b_seg ? scalar(@a_seg) : scalar(@b_seg);
  for (my $i = 0; $i < $max; $i++) {
    if ($i >= @a_seg) { return -1; }
    if ($i >= @b_seg) { return 1; }

    my ($a_has, $a_num, $a_slug) = parse_segment_for_sort($a_seg[$i]);
    my ($b_has, $b_num, $b_slug) = parse_segment_for_sort($b_seg[$i]);

    # Ordered segments come first, then unordered alphabetically.
    if ($a_has != $b_has) {
      return $a_has ? -1 : 1;
    }

    if ($a_has && $b_has && $a_num != $b_num) {
      return $a_num <=> $b_num;
    }

    my $name_cmp = $a_slug cmp $b_slug;
    return $name_cmp if $name_cmp != 0;
  }

  # Keep ":-" variants after non-legacy variants when names otherwise tie.
  my $a_legacy = ($file_a =~ /:-/) ? 1 : 0;
  my $b_legacy = ($file_b =~ /:-/) ? 1 : 0;
  if ($a_legacy != $b_legacy) {
    return $a_legacy <=> $b_legacy;
  }

  return $file_a cmp $file_b;
}

opendir my $dh, $source_root or die "Cannot open $source_root: $!\n";
my @md_files = sort { cmp_files($a, $b) } map { decode('UTF-8', $_) } grep {
  /\.md$/ &&
  $_ ne '_Sidebar.md' &&
  $_ ne '_Footer.md' &&
  -f "$source_root/$_"
} readdir $dh;
closedir $dh;

my @rows;
my %dest_seen;

for my $src (@md_files) {
  if ($src eq 'Home.md') {
    push @rows, [$src, 'index.md'];
    $dest_seen{'index.md'} = 1;
    next;
  }

  (my $stem = $src) =~ s/\.md$//;
  my @raw_segments = split_segments($stem);
  my @seg = map { slugify($_) } @raw_segments;
  next unless @seg;

  my $dest;

  if ($seg[0] eq 'getting-started') {
    my $page = join_slug(@seg[1..$#seg]);
    $dest = "getting-started/$page.md";
  } elsif ($seg[0] eq 'developer-guides') {
    my $page = join_slug(@seg[1..$#seg]);
    $dest = "developer-guides/$page.md";
  } elsif ($seg[0] eq 'specific-server-providers-setups') {
    my $page = join_slug(@seg[1..$#seg]);
    $dest = "additional-setup/provider-setups/$page.md";
  } elsif ($seg[0] eq 'additional-setup') {
    my $page = join_slug(@seg[1..$#seg]);
    my $bucket = classify_additional_setup($page);
    $dest = "additional-setup/$bucket/$page.md";
  } elsif ($seg[0] eq 'user-guide') {
    if (@seg >= 3 && $seg[1] eq 'main-interface') {
      if (@seg == 3) {
        $dest = "user-guide/main-interface/$seg[2].md";
      } else {
        my $section = $seg[2];
        my $page = join_slug(@seg[3..$#seg]);
        $dest = "user-guide/main-interface/$section/$page.md";
      }
    } else {
      my $page = join_slug(@seg[1..$#seg]);
      $dest = "user-guide/$page.md";
    }
  } elsif ($seg[0] =~ /^troubleshooting/ || $seg[0] eq 'help') {
    my $bucket = (@seg >= 2 && $seg[1] =~ /common-procedures/) ? 'common-procedures' : 'need-help';
    my $page = @seg >= 3 ? join_slug(@seg[2..$#seg]) : join_slug(@seg[1..$#seg]);
    $dest = "troubleshooting/$bucket/$page.md";
  } else {
    my $first = $seg[0];
    my $page = join_slug(@seg[1..$#seg]);
    $dest = "$first/$page.md";
  }

  if ($dest_seen{$dest}) {
    my $base = $dest;
    $base =~ s/\.md$//;
    if ($src =~ /:-/) {
      $dest = "$base-legacy.md";
    } else {
      my $n = 2;
      my $try = "$base-$n.md";
      while ($dest_seen{$try}) {
        $n++;
        $try = "$base-$n.md";
      }
      $dest = $try;
    }
  }

  $dest_seen{$dest} = 1;
  push @rows, [$src, $dest];
}

open my $out, '>:encoding(UTF-8)', $out_file or die "Cannot write $out_file: $!\n";
print {$out} "# Auto-generated by mkdocs/scripts/generate_wiki_sync_map.pl\n";
print {$out} "# Source wiki file<TAB>destination path under mkdocs/docs<TAB>optional nav label override\n";
for my $r (@rows) {
  print {$out} "$r->[0]\t$r->[1]\n";
}
close $out;

print "Generated $out_file with ", scalar(@rows), " entries from $source_root\n";
