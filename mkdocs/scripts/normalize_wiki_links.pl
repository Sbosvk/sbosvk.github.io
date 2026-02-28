#!/usr/bin/env perl
use strict;
use warnings;
use Encode qw(encode decode);
use File::Find;
use File::Spec;

my $repo_root = '.';
my $docs_root = File::Spec->rel2abs("$repo_root/mkdocs/docs");
my $map_file  = "$repo_root/mkdocs/scripts/wiki_sync_map.tsv";

die "Missing docs root: $docs_root\n" unless -d $docs_root;
die "Missing map file: $map_file\n" unless -f $map_file;

sub trim {
  my ($s) = @_;
  $s =~ s/^\s+|\s+$//g;
  return $s;
}

sub url_encode_utf8 {
  my ($text) = @_;
  my $bytes = encode('UTF-8', $text);
  $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf("%%%02X", ord($1))/ge;
  return $bytes;
}

sub url_decode {
  my ($text) = @_;
  my $bytes = $text;
  $bytes =~ s/%([0-9A-Fa-f]{2})/pack('C', hex($1))/ge;
  return decode('UTF-8', $bytes);
}

sub to_rel {
  my ($from_file_abs, $target_rel) = @_;
  my ($vol, $dirs, undef) = File::Spec->splitpath($from_file_abs);
  my $from_dir = File::Spec->catpath($vol, $dirs, '');
  my $target_abs = File::Spec->catfile($docs_root, split('/', $target_rel));
  my $rel = File::Spec->abs2rel($target_abs, $from_dir);
  $rel =~ s{\\}{/}g;
  return $rel;
}

# Build wiki-slug -> destination map from the authoritative TSV mapping.
my %slug_to_dest;
open my $mf, '<:encoding(UTF-8)', $map_file or die "Cannot read $map_file: $!\n";
while (my $line = <$mf>) {
  chomp $line;
  next if $line =~ /^\s*$/;
  next if $line =~ /^\s*#/;

  my ($src, $dest) = split /\t/, $line, 3;
  next unless defined $src && defined $dest;

  $src = trim($src);
  $dest = trim($dest);
  next unless length($src) && length($dest);
  next unless $src =~ /\.md$/;

  (my $stem = $src) =~ s/\.md$//;
  my $slug = url_encode_utf8($stem);
  $slug_to_dest{$slug} //= $dest;
}
close $mf;

my @files;
find(
  sub {
    return unless -f $_;
    return unless $_ =~ /\.md$/;
    push @files, $File::Find::name;
  },
  $docs_root
);

for my $file (@files) {
  open my $in, '<', $file or die "Cannot read $file: $!";
  local $/;
  my $content = <$in>;
  close $in;

  my $original = $content;

  # Remove old wiki breadcrumb line if present at top.
  $content =~ s/\A[^\n]*You are here[^\n]*\n+//;

  # Rewrite wiki links from any owner/repo to local relative links.
  $content =~ s{https://github\.com/[^/\s)"'>]+/[^/\s)"'>]+/wiki(?:/([^\s)"'>]*))?}{
    my $slug_full = defined($1) && length($1) ? $1 : 'Home';
    my ($slug, $anchor) = split(/#/, $slug_full, 2);
    my $slug_canonical = url_encode_utf8(url_decode($slug));

    my $target_rel;
    if (exists $slug_to_dest{$slug}) {
      $target_rel = $slug_to_dest{$slug};
    } elsif (exists $slug_to_dest{$slug_canonical}) {
      $target_rel = $slug_to_dest{$slug_canonical};
    } elsif ($slug =~ m{^images/} && -f File::Spec->catfile($docs_root, split('/', $slug))) {
      # Handle direct wiki image links.
      $target_rel = $slug;
    }

    if (defined $target_rel) {
      my $rel = to_rel($file, $target_rel);
      defined $anchor ? "$rel#$anchor" : $rel;
    } else {
      "https://github.com/MarechJ/hll_rcon_tool/wiki/$slug_full";
    }
  }ge;

  if ($content ne $original) {
    open my $out, '>', $file or die "Cannot write $file: $!";
    print {$out} $content;
    close $out;
  }
}

print "Processed ", scalar(@files), " markdown files\n";
