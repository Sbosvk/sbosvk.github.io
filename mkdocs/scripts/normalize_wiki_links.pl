#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Spec;

my $docs_root = File::Spec->rel2abs('mkdocs/docs');

my %map = (
  'Home' => 'index.md',

  'Getting-Started-%E2%80%90-Presentation-and-features' => 'getting-started/presentation-and-features.md',
  'Getting-Started-%E2%80%90-Requirements' => 'getting-started/requirements.md',
  'Getting-Started-%E2%80%90-Installation' => 'getting-started/installation.md',

  'User-Guide-%E2%80%90-Admin-panel' => 'user-guide/admin-panel.md',
  'User-Guide-%E2%80%90-main-interface-%E2%80%90-Home' => 'user-guide/main-interface/home.md',
  'User-Guide-%E2%80%90-main-interface-%E2%80%90-Views-%E2%80%90-Live' => 'user-guide/main-interface/views/live.md',
  'User-Guide-%E2%80%90-main-interface-%E2%80%90-Views-%E2%80%90-Team' => 'user-guide/main-interface/views/team.md',
  'User-Guide-%E2%80%90-main-interface-%E2%80%90-Maps-%E2%80%90-Change' => 'user-guide/main-interface/maps/change.md',
  'User-Guide-:-main-interface-%E2%80%90-Maps-%E2%80%90-Change' => 'user-guide/main-interface/maps/change-legacy.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Maps-%E2%80%90-Rotation' => 'user-guide/main-interface/maps/rotation.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Maps-%E2%80%90-Objectives' => 'user-guide/main-interface/maps/objectives.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Maps-%E2%80%90-Votemap' => 'user-guide/main-interface/maps/votemap.md',

  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Records-%E2%80%90-Players' => 'user-guide/main-interface/records/players.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Records-%E2%80%90-Blacklist' => 'user-guide/main-interface/records/blacklist.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Records-%E2%80%90-Game-Logs' => 'user-guide/main-interface/records/game-logs.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Records-%E2%80%90-Audit-Logs' => 'user-guide/main-interface/records/audit-logs.md',

  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-General' => 'user-guide/main-interface/settings/general.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Services' => 'user-guide/main-interface/settings/services.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Welcome-message' => 'user-guide/main-interface/settings/welcome-message.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Broadcast-message' => 'user-guide/main-interface/settings/broadcast-message.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Console-Admins' => 'user-guide/main-interface/settings/console-admins.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Vips' => 'user-guide/main-interface/settings/vips.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Templates' => 'user-guide/main-interface/settings/templates.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Profanity-filter' => 'user-guide/main-interface/settings/profanity-filter.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Settings-%E2%80%90-Autosettings' => 'user-guide/main-interface/settings/autosettings.md',

  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Audit' => 'user-guide/main-interface/webhooks/audit.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Admin-Ping' => 'user-guide/main-interface/webhooks/admin-ping.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Watchlist' => 'user-guide/main-interface/webhooks/watchlist.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Camera' => 'user-guide/main-interface/webhooks/camera.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Chat' => 'user-guide/main-interface/webhooks/chat.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Kill-TK' => 'user-guide/main-interface/webhooks/kill-tk.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Webhooks-%E2%80%90-Log-Line' => 'user-guide/main-interface/webhooks/log-line.md',

  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-Level' => 'user-guide/main-interface/automods/level.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-No-Leader' => 'user-guide/main-interface/automods/no-leader.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-Seeding' => 'user-guide/main-interface/automods/seeding.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-No-Solo-Tank' => 'user-guide/main-interface/automods/no-solo-tank.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-VAC-Game-bans' => 'user-guide/main-interface/automods/vac-game-bans.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-TK-Ban-On-Connect' => 'user-guide/main-interface/automods/tk-ban-on-connect.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Automods-%E2%80%90-Name-kicks' => 'user-guide/main-interface/automods/name-kicks.md',

  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Seeder-VIP-Reward' => 'user-guide/main-interface/others/seeder-vip-reward.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-RCON-Game-Server-Connection' => 'user-guide/main-interface/others/rcon-game-server-connection.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-CRCON-Settings' => 'user-guide/main-interface/others/crcon-settings.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Chat-Commands' => 'user-guide/main-interface/others/chat-commands.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-RCON-Chat-Commands' => 'user-guide/main-interface/others/rcon-chat-commands.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Scorebot' => 'user-guide/main-interface/others/scorebot.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Scoreboard' => 'user-guide/main-interface/others/scoreboard.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Steam-API' => 'user-guide/main-interface/others/steam-api.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Expired-VIP' => 'user-guide/main-interface/others/expired-vip.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-GTX-server-name-change' => 'user-guide/main-interface/others/gtx-server-name-change.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Log-Stream' => 'user-guide/main-interface/others/log-stream.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Others-%E2%80%90-Watch-Kill-Rate' => 'user-guide/main-interface/others/watch-kill-rate.md',

  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Stats-%E2%80%90-Live-Sessions' => 'user-guide/main-interface/stats/live-sessions.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Stats-%E2%80%90-Live-Game' => 'user-guide/main-interface/stats/live-game.md',
  'User-Guide-%E2%80%90-Main-interface-%E2%80%90-Stats-%E2%80%90-Games' => 'user-guide/main-interface/stats/games.md',

  'Additional-Setup-%E2%80%90-Discord-Integration' => 'additional-setup/additional-installs/discord-integration.md',
  'Additional-Setup-%E2%80%90-Multiple-CRCON-Instances' => 'additional-setup/additional-installs/multiple-crcon-instances.md',
  'Additional-Setup-%E2%80%90-Update-or-downgrade' => 'additional-setup/additional-installs/update-or-downgrade.md',
  'Additional-Setup-%E2%80%90-Community-Tools' => 'additional-setup/additional-installs/community-tools.md',
  'Additional-Setup-%E2%80%90-Manual-backup' => 'additional-setup/backup/manual-backup.md',
  'Additional-Setup-%E2%80%90-Backup-and-restore-settings' => 'additional-setup/backup/backup-and-restore-settings.md',
  'Additional-Setup-%E2%80%90-Database-%E2%80%90-Automated-backup' => 'additional-setup/backup/database-automated-backup.md',
  'Additional-Setup-%E2%80%90-Migrate-CRCON-to-another-VPS' => 'additional-setup/moving-servers/migrate-crcon-to-another-vps.md',
  'Additional-Setup-%E2%80%90-Replace-the-game-server-managed-in-CRCON' => 'additional-setup/moving-servers/replace-managed-game-server.md',
  'Additional-Setup-%E2%80%90-Adding-a-game-server-to-manage-in-CRCON' => 'additional-setup/moving-servers/add-game-server.md',

  'Specific-server-providers-setups-%E2%80%90-AWS' => 'additional-setup/provider-setups/aws.md',
  'Specific-server-providers-setups-%E2%80%90-Cloudflare' => 'additional-setup/provider-setups/cloudflare.md',
  'Specific-server-providers-setups-%E2%80%90-Digital-Ocean' => 'additional-setup/provider-setups/digital-ocean.md',
  'Specific-server-providers-setups-%E2%80%90-Kubernetes' => 'additional-setup/provider-setups/kubernetes.md',
  'Specific-server-providers-setups-%E2%80%90-Traefik' => 'additional-setup/provider-setups/traefik.md',

  'Developer-Guides-%E2%80%90-Overview---Project-Structure' => 'developer-guides/overview-project-structure.md',
  'Developer-Guides-%E2%80%90-Development-environment' => 'developer-guides/development-environment.md',
  'Developer-Guides-%E2%80%90-Building-your-own-Docker-images' => 'developer-guides/building-your-own-docker-images.md',
  'Developer-Guides-%E2%80%90-CRCON-API' => 'developer-guides/crcon-api.md',
  'Developer-Guides-%E2%80%90-v9.x-to-v10.0.0-API-Changes' => 'developer-guides/v9-to-v10-api-changes.md',
  'Developer-Guides-%E2%80%90-Streaming-Logs' => 'developer-guides/streaming-logs.md',
  'Developer-Guides-%E2%80%90-Remotely-connect-to-the-PostgreSQL-database' => 'developer-guides/remotely-connect-to-postgresql.md',
  'Developer-Guides-%E2%80%90-Miscellaneous' => 'developer-guides/miscellaneous.md',
  'Developer-Guides-%E2%80%90-HLL-RCON-Commands' => 'developer-guides/hll-rcon-commands.md',
  'Developer‐Guides-‐-HLL-RCONv2-Commands' => 'developer-guides/hll-rconv2-commands.md',

  'Troubleshooting-&-Help-%E2%80%90-Common-procedures-%E2%80%90-How-to-enter-a-SSH-terminal' => 'troubleshooting/common-procedures/how-to-enter-an-ssh-terminal.md',
  'Troubleshooting-&-Help-%E2%80%90-Common-procedures-%E2%80%90-Docker-cleanup' => 'troubleshooting/common-procedures/docker-cleanup.md',
  'Troubleshooting-&-Help-%E2%80%90-Common-procedures-%E2%80%90-Reduce-database-size' => 'troubleshooting/common-procedures/reduce-database-size.md',
  'Troubleshooting-&-Help-%E2%80%90-Need-help-%3F-%E2%80%90-Common-issues-and-their-solutions' => 'troubleshooting/need-help/common-issues-and-solutions.md',
  'Troubleshooting-&-Help-%E2%80%90-Need-help-%3F-%E2%80%90-Report-an-issue' => 'troubleshooting/need-help/report-an-issue.md',

  # Legacy aliases found in docs
  'Help-%E2%80%90-Common-issues-and-their-solutions' => 'troubleshooting/need-help/common-issues-and-solutions.md',
  'Help-%E2%80%90-Report-an-issue' => 'troubleshooting/need-help/report-an-issue.md',
  'Migrating' => 'additional-setup/moving-servers/migrate-crcon-to-another-vps.md',

  # Remote wiki image links
  'images/create_droplet.png' => 'images/create_droplet.png',
  'images/example_droplet.png' => 'images/example_droplet.png',
);

sub to_rel {
  my ($from_file_abs, $target_rel) = @_;
  my ($vol, $dirs, undef) = File::Spec->splitpath($from_file_abs);
  my $from_dir = File::Spec->catpath($vol, $dirs, '');
  my $target_abs = File::Spec->catfile($docs_root, split('/', $target_rel));
  my $rel = File::Spec->abs2rel($target_abs, $from_dir);
  $rel =~ s{\\}{/}g;
  return $rel;
}

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

  # Remove old wiki breadcrumb line if present at top.
  # This handles variants in spacing/punctuation/emoji form.
  $content =~ s/\A[^\n]*You are here[^\n]*\n+//;

  my $changed = 0;
  $content =~ s{https://github\.com/MarechJ/hll_rcon_tool/wiki(?:/([^\s)"'>]*))?}{
    my $slug_full = defined($1) && length($1) ? $1 : 'Home';
    my ($slug, $anchor) = split(/#/, $slug_full, 2);
    if (exists $map{$slug}) {
      my $rel = to_rel($file, $map{$slug});
      $changed = 1;
      defined $anchor ? "$rel#$anchor" : $rel;
    } else {
      "https://github.com/MarechJ/hll_rcon_tool/wiki/$slug_full";
    }
  }ge;

  if ($changed || $content ne do { open my $c, '<', $file; local $/; my $x = <$c>; close $c; $x }) {
    open my $out, '>', $file or die "Cannot write $file: $!";
    print {$out} $content;
    close $out;
  }
}

print "Processed ", scalar(@files), " markdown files\n";
