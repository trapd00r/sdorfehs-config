#!/usr/bin/perl
# abstract: feed the sdorfehs sticky bar
# vim: ft=perl:fdm=marker:fmr=#<,#>:fen:et:sw=2:
use strict;
use warnings FATAL => 'all';
use vars     qw($VERSION);
use autodie  qw(:all);

use utf8;
use open qw(:std :utf8);

use Term::ExtendedColor::Dzen qw(fgd bgd);

use DBI;
use Time::Date;
use IPC::Cmd qw(run);
#use Music::Beets::Info qw(beet_info);

use Data::Dumper;

my $SDORFEHS_BAR_PIPE = "$ENV{XDG_CONFIG_HOME}/sdorfehs/bar";

np();


sub date {
  use Date::Language;
  my $lang = Date::Language->new('English');
#  return $lang->time2str("%H:%M", time);
  return $lang->time2str("%H:%M:%S", time);
#  return $lang->time2str("%a %d/%m %H:%M", time);
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

  return $vscreen_bar;
}

sub np {
  open(my $pipe, '>', $SDORFEHS_BAR_PIPE) or die $!;
  $pipe->autoflush(1);
  select $pipe;

  my $bar = fgd('#484848', '│');

  while(1) {
    # FIXME
    my $data;
    $data->{artist} = `plexampnp -a`;
    $data->{album} = `plexampnp -A`;
    $data->{title} = `plexampnp -t`;
    $data->{year} = `plexampnp -y`;

    for my $k(keys(%{$data})) {
      chomp($data->{$k});
    }

#   execute fun stuff on click
    my $goto_album_dir         = sprintf "^ca(1, %s)", 'plexamp-goto-album-dir';
    my $goto_artist_dir        = sprintf "^ca(1, %s)", 'plexamp-goto-artist-dir';
    my $copy_path_to_clipboard = sprintf "^ca(1, %s)", 'plexamp-copy-path-to-clipboard';

    printf "$copy_path_to_clipboard'%s'^ca() by $goto_artist_dir%s^ca() on $goto_album_dir%s^ca() [%s] %s\n",
      bold(fgd('#afaf00', $data->{title})),
      bold(fgd('#afd700', $data->{artist})),
      bold(fgd('#87af5f', $data->{album} ? $data->{album} : 'Other')),
      bold(fgd('#87afff', $data->{year} ? $data->{year} : '')),
    sleep 5;
  }
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

sub fn {
#  return $_[0]
#    ? sprintf("^fn('Anonymous Pro:pixelsize=10:style=bold', $_[0])^fn()")
#    : '^fn()';
}

#sub hass {
#  my $database = $ENV{HASS_DB_DATABASE};
#  my $hostname = $ENV{HASS_DB_HOST};
#  my $port     = $ENV{HASS_DB_PORT};
#
#  my $user     = $ENV{HASS_DB_USER};
#  my $password = $ENV{HASS_DB_PASSWORD};
#
#  my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
#  my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 1 });
#
#  my $sql = q{
#    SELECT
#      state
#    FROM
#      states
#    WHERE
#      entity_id = 'sensor.magnus_sitter_vid_datorn'
#    ORDER BY
#      state_id DESC
#    LIMIT 1
#  };
#
#
#  my $sth = $dbh->prepare($sql);
#  $sth->execute;
#
#  my $status = values %{ $sth->fetchrow_hashref() };
#
#  return sprintf "%s", $status > 0 ? 'Magnus haxxar' : 'Magnus haxxar inte';
#}
