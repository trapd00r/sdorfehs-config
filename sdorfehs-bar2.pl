#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use utf8;
use open qw(:std :utf8);

#use DDP;
use v5.30;

use Term::ExtendedColor::Dzen qw(fgd bgd);
use Data::Dumper;
use DBI;
use Time::Date;
use IPC::Cmd qw(run);


my $SDORFEHS_BAR_PIPE = "$ENV{XDG_CONFIG_HOME}/sdorfehs/bar";
my $SDORFEHS_BAR_SEPARATOR = ' | ';


create_bar([
  np(),
  date(),
  fmt_vscreen_list(),
]);

sub create_bar {
  my $bar = shift;

  my $bar_string = join($SDORFEHS_BAR_SEPARATOR, @$bar);
  printf "$bar_string\n";

}


sub date {
  use Date::Language;
  my $lang = Date::Language->new('English');
  return $lang->time2str("%H:%M:%S", time);
}


sub fmt_vscreen_list {
  my $buffer;

  scalar run(
    command => "sdorfehs -c vscreens",
    verbose => 0,
    buffer  => \$buffer,
    timeout => 0,
  );

  my @vscreens = split(/\n/, $buffer);

  my @sorted = sort { $a =~ m/^\d+[*]/ ? -1 : 1 } @vscreens;

  my $vscreen_bar = ($sorted[0] =~ s/[+*-]/ /r);
  return bgd('#ff0000', fgd('#ffff00', $vscreen_bar))

}


sub np {
  use JSON;
  my $np = decode_json(`plexampnp --json`);

  # parentTitle = album
  # grandparentTitle = artist
  # title = track
  # year = year

  my $goto_album_dir         = sprintf "^ca(1, %s)", 'plexamp-goto-album-dir';
  my $goto_artist_dir        = sprintf "^ca(1, %s)", 'plexamp-goto-artist-dir';
  my $copy_path_to_clipboard = sprintf "^ca(1, %s)", 'plexamp-copy-path-to-clipboard';

  my $formatted_np = sprintf("$copy_path_to_clipboard'%s'^ca() by $goto_artist_dir%s^ca() on $goto_album_dir%s^ca() [%s]",
    bold(fgd('#afaf00', $np->{Track}->{title})),
    bold(fgd('#afd700', $np->{Track}->{grandparentTitle})),
    bold(fgd('#87af5f', $np->{Track}->{parentTitle} ? $np->{Track}->{parentTitle} : 'Other')),
    bold(fgd('#87afff', $np->{Track}->{year} ? $np->{Track}->{year} : '')));




  return $formatted_np;

}

sub get_scrobble {
#  my $query = "SELECT artist,title,album,CAST(scrobbled_on AS DATE) as first_scrobble, COUNT(*) AS count FROM scrobbles WHERE artist = '$artist' AND title like '$title' GROUP BY title ORDER BY count DESC LIMIT 10";
}


sub white {
  return fgd('#fff', shift);
}

sub bold {
# font issues after upgrade...
  return $_[0];
  return "^fn('Anonymous Pro:style=Bold:pixelsize=10:antialias=1:hinting=1:hintstyle=3')" . $_[0] . '^fn()';
}

sub italic {
  return "^fn('Anonymous Pro:style=Italic:pixelsize=10:antialias=1:hinting=1:hintstyle=3')" . $_[0] . '^fn()';
}

sub nc {
  return fgd('#0087ff', shift) . fgd();
}


sub fmt_volume {
  chomp(my $volume = `pulsemixer --get-volume | awk '{print \$1}'`);
  return $volume;
}


