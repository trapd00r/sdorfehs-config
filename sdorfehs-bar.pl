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

use Audio::MPD;
use Time::Date;
use Music::Beets::Info qw(beet_info);
my $mpd = Audio::MPD->new;

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

sub np {
  open(my $pipe, '>', $SDORFEHS_BAR_PIPE) or die $!;
  $pipe->autoflush(1);
  select $pipe;

  my $bar = fgd('#484848', '│');

  while(1) {
    PLAY_CHECK:
    if($mpd->status->state ne 'play') {
      printf "mpd paused %s %s\n", $bar, bold(fgd('#ff005f', date()));

      sleep 5;
      goto PLAY_CHECK;
    }
    my $time = date();

    use Encode;
    my $data = beet_info("$ENV{XDG_MUSIC_DIR}" . $mpd->current->file);

#   fulhack
    for my $k(keys(%{$data})) {
#      $data->{$k} = decode_utf8($data->{$k});
    }

    $data->{bitrate} = exists($data->{bitrate})
      ? sprintf "%d", $data->{bitrate} / 1000
      : 0;

    if($data->{original_date}) {
      my $t = Time::Date->new($data->{original_date});
      $data->{original_date} = sprintf("%s", bgd('#ff0000', $t->strftime("%d %B, %Y")));
    }
    else {
      $data->{original_date} = '';
    }

    if($data->{label}) {
      $data->{label} = fgd('#ffff00', $data->{label});
    }
    else {
      $data->{label} = '';
    }
    if(exists($data->{format})) {
      $data->{format} = lc($data->{format});
    }
    else {
      $data->{format} = 'weird';
    }

    if(exists($data->{genre})) {
      $data->{genre} = lc($data->{genre});
    }
    else {
      $data->{genre} = 'undef';
    }

    if($data->{myartist}) {
      $data->{artist} = $data->{artist} . ' (' . fgd('#ffff00', $data->{myartist}) . ')';
    }


#   execute fun stuff on click
    my $goto_album_dir         = sprintf "^ca(1, %s)", 'mpd-goto-album-dir';
    my $goto_artist_dir        = sprintf "^ca(1, %s)", 'mpd-goto-artist-dir';
    my $copy_path_to_clipboard = sprintf "^ca(1, %s)", 'mpd-copy-path-to-clipboard';

#    printf "%s the %s song '%s' by $goto_artist_dir%s^ca() on $goto_album_dir%s^ca() released %s on %s. It's track %s/%s and the bitrate is %s kbps (%s).\n",
    printf "%s the %s song $copy_path_to_clipboard'%s'^ca() by $goto_artist_dir%s^ca() on $goto_album_dir%s^ca() released %s on %s $bar %s\n",
      fgd('#ef0e99', bold('▶')),
      white(bold(lc($data->{genre}))),
      bold(fgd('#afaf00', $data->{title})),
      bold(fgd('#afd700', $data->{artist})),
      bold(fgd('#87af5f', $data->{album} ? $data->{album} : 'Other')),
      bold(nc($data->{original_date} ? $data->{original_date} : $data->{year})),
      bold($data->{label} ? $data->{label} : 'Other'),
      bold(fgd('#ff005f', $time));
    sleep 4;
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
