use ExtUtils::MakeMaker;
use Config;

$LDDLFLAGS = '';
$LDDLFLAGS = '-all_load' if $^O eq 'darwin';

if ($^O =~ /win/i) {
        $LIBS = '-logg_static -lvorbis_static -lvorbisfile_static';
} else {
        $LIBS = '-logg -lvorbis -lvorbisfile';
}

WriteMakefile(
	'NAME'		=> 'Ogg::Vorbis::Decoder',
	'VERSION_FROM'	=> 'Decoder.pm',
	'LIBS'		=> [$LIBS],
	'DEFINE'	=> '-O',
	'LDDLFLAGS'	=> "$Config{'lddlflags'} $LDDLFLAGS"
);
