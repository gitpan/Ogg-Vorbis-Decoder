require 5.005;
use ExtUtils::MakeMaker;

use Config qw(%Config);

sub MY::libscan {
	my ($self,$path) = @_;

	return '' if (
		$path =~ /(?:RCS|CVS|SCCS)/ or
		$path =~ /[~%]$/ or
		$path =~ /\.(orig|rej)$/
	);
	return $path;
}

print "Checking for 'vorbisfile.h'\n";
my $include = '';
my @inc = split /\s+/,join(' ',$Config{'usrinc'},$Config{'incpth'},$Config{'locincpth'});
foreach my $path (@inc) {
	if (-f "$path/vorbisfile.h") {
		print "Checking in $path/...\n";
		$include .= "-I$path ";
        	last;
	} elsif (-f "$path/vorbis/vorbisfile.h") {
		print "Checking in $path/vorbis/...\n";
		$include .= "-I$path/vorbis ";
		last;
	}
}

die "I can't find 'vorbisfile.h' - Exiting!\n" if $include =~ /^\s*$/;

$LDDLFLAGS = '';
$LDDLFLAGS = '-all_load' if $^O eq 'darwin';

WriteMakefile(
	'NAME'		=> 'Ogg::Vorbis::Decoder',
	'VERSION_FROM'	=> 'Decoder.pm',
	'LIBS'		=> ['-logg -lvorbis -lvorbisfile'],
	'DEFINE'	=> '-g',
	'INC'		=> $include,
	'LDDLFLAGS'	=> "$Config{'lddlflags'} $LDDLFLAGS"
);
