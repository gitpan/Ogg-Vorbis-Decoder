package Ogg::Vorbis::Decoder;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use Inline C => 'DATA',
					LIBS => '-logg -lvorbis -lvorbisfile',
					VERSION => '0.01',
					NAME => 'Ogg::Vorbis::Decoder';

# constructors

sub open {
	my ($id, $path) = @_;
	$id = ref($id) || $id;
	_new($id, $path);
}

# decoding methods

sub read {
	my ($self, $buffer) = (shift, shift);
	my %params = (	buffsize => 4096,  # 4096 byte buffer
									bigendianp => 0, # little endian
									word => 2, # 16-bit words
									signed => 1, # signed data
									bitstream => 0 # dummy value
								);
	my %cust = @_;
	while (my ($k, $v) = each %cust) {
		if (exists $params{$k}) {
			if ($k eq 'buffsize' && $v !~ /^\d+$/) {
				carp "$v is not a valid buffsize, using default" if $^W;
			} elsif ($k eq 'bigendianp' && ($v ne '0' || $v ne '1')) {
				carp "$v is not a valid bigendianp, using default" if $^W;
			} elsif ($k eq 'word' && ($v ne '1' || $v ne '2')) {
				carp "$v is not a valid word setting, using default" if $^W;
			} elsif ($k eq 'signed' && ($v ne '0' || $v ne '1')) {
				carp "$v is not a valid signed setting, using default" if $^W;
			} elsif ($k eq 'bitstream' && $v !~ /^d+$/) {
				carp "$v is not a valid bitstream, using default" if $^W;
			} elsif ($k eq 'bitstream') {
				$self->{BSTREAM} = $v;
			} else {
				$params{$k} = $v;
			}
		} else {
			carp "$k is not a valid parameter, ignoring" if $^W;
		}
	}
	return $self->_read($buffer, $params{buffsize}, $params{bigendianp},
		$params{word}, $params{signed});
}

sub raw_seek {
	my ($self, $pos) = @_;
	if ($pos !~ /^-?\d+$/) {
		carp "$pos is not a valid position (long), aborting seek" if $^W;
		return undef;
	}

	return $self->_raw_seek($pos);
}

sub pcm_seek {
	my ($self, $pos, $page) = @_;
	$page ||= 0;
	$page = 1 if $page;
	if ($pos !~ /^-?\d+$/) {
		carp "$pos not a valid postion (ogg_int64_t), aborting seek" if $^W;
		return undef;
	}
	
	return $self->_pcm_seek($pos, $page);
}

sub time_seek {
	my ($self, $pos, $page) = @_;
	$page ||= 0;
	$page = 1 if $page;
	if ($pos =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
		carp "$pos is not a valid position (double), aborting seek" if $^W;
		return undef;
	}

	return $self->_raw_seek($pos, $page);
}

sub get_current_bitstream {
	my $self = shift;
	return $self->{BSTREAM};
}

# informational methods -- see Ogg::Vorbis::Header for
# non-decoding-specific info

sub bitrate {
	my ($self, $stream) = @_;
	$stream ||= -1;
	if ($stream !~ /^-?\d+$/) {
		carp "$stream is not a valid stream, using default value" if $^W;
		$stream = -1;
	}

	return $self->_bitrate($stream);
}

sub serialnumber {
	my ($self, $stream) = @_;
	$stream ||= -1;
	if ($stream !~ /^-?\d+$/) {
		carp "$stream is not a valid stream, using default value" if $^W;
		$stream = -1;
	}

	return $self->_serialnumber($stream);
}

sub raw_total {
	my ($self, $stream) = @_;
	$stream ||= -1;
	if ($stream !~ /^-?\d+$/) {
		carp "$stream is not a valid stream, using default" if $^W;
		$stream = -1;
	}

	return $self->_raw_total($stream);
}

sub pcm_total {
	my ($self, $stream) = @_;
	$stream ||= -1;
	if ($stream !~ /^-?\d+$/) {
		carp "$stream is not a valid stream, using default" if $^W;
		$stream = -1;
	}

	return $self->_pcm_total($stream);
}

sub time_total {
	my ($self, $stream) = @_;
	$stream ||= -1;
	if ($stream !~ /^-?\d+$/) {
		carp "$stream is not a valid stream, using default" if $^W;
		$stream = -1;
	}

	return $self->_time_total($stream);
}

sub raw_tell {
	my $self = shift;
	return $self->_raw_tell;
}

sub pcm_tell {
	my $self = shift;
	return $self->_pcm_tell;
}

sub time_tell {
	my $self = shift;
	return $self->_time_tell;
}

1;
__DATA__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Ogg::Vorbis::Decoder - An object-oriented Ogg Vorbis to decoder

=head1 SYNOPSIS

  use Ogg::Vorbis::Decoder;
  my $decoder = Ogg::Vorbis::Decoder->open("song.ogg");
	my $buffer;
	while ((my $len = $decoder->read($buffer) > 0) {
		# do something with the PCM stream
	}

=head1 DESCRIPTION

This module provides users with Decoder objects for Ogg Vorbis files.
One can read data in PCM format from the stream, seek by raw bytes,
pcm samples, or time, and gather decoding-specific information not
provided by Ogg::Vorbis::Header.  Currently, we provide no support for
the callback mechanism provided by the Vorbisfile API; this may be
included in future releases.

=head1 CONSTRUCTOR

=head2 C<open ($filename)>

Opens an Ogg Vorbis file for decoding.  It opens a handle to the 
file and initializes all of the internal vorbis decoding structures.
Note that the object will maintain open file descriptors until the
object is collected by the garbage handler.  Returns C<undef> on
failure.

=head1 INSTANCE METHODS

=head2 C<read ($buffer, [%params])>

Reads PCM data from the Vorbis stream into C<$buffer>.  Returns the
number of bytes read, 0 when it reaches the end of the stream, or a
value less than 0 on error.  The optional params hash can contain the
following keys (with corresponding default values):
C<{ buffsize => 4096, bigendianp => 0, word => 2, signed => 1,
bitstream => 0 }>.  Consult the Vorbisfile API
(http://www.xiph.org/ogg/vorbis/doc/vorbisfile/reference.html) for an
explanation of the various values.  Note that OVD maintains the
bitstream value internally.  Providing a new bitstream to C<read> will
automatically update this value within the object.

=head2 C<raw_seek ($pos)>

Seeks through the compressed bitstream to the offset specified by
C<$pos> in raw bytes.  Returns 0 on success.

=head2 C<pcm_seek ($pos, [$page])>

Seeks through the bitstream to the offset specified by C<$pos> in pcm
samples.  The optional C<$page> parameter is a boolean flag that, if
set to true, will cause the method to seek to the closest full page
preceding the specified location.  Returns 0 on success.

=head2 C<time_seek ($pos, [$page])>

Seeks through the bitstream to the offset specified by C<$pos> in
seconds.  The optional C<$page> parameter is a boolean flag that, if
set to true, will cause the method to seek to the closest full page
preceding the specified location.  Returns 0 on success.

=head2 C<get_current_bitstream ()>

Returns the current logical bitstream of the decoder.  This matches the
bitstream paramer optionally passed to C<read>.  Useful for saving a
bitstream to jump to later or to pass to various information methods.

=head2 C<bitrate ([$stream])>

Returns the average bitrate for the specified logical bitstream.  If
C<$stream> is left out or set to -1, the average bitrate for the entire
stream will be reported.

=head2 C<bitrate_instant ()>

Returns the most recent bitrate read from the file.  Returns 0 if no
read has been performed or bitrate has not changed.

=head2 C<streams ()>

Returns the number of logical bitstreams in the file.

=head2 C<seekable ()>

Returns non-zero value if file is seekable, 0 if not.

=head2 C<serialnumber ([$stream])>

Returns the serial number of the specified logical bitstream, or that
of the current bitstream if C<$stream> is left out or set to -1.

=head2 C<raw_total ([$stream])>

Returns the total number of bytes in the physical bitstream or the
specified logical bitstream.

=head2 C<pcm_total ([$stream])>

Returns the total number of pcm samples in the physical bitstream or the
specified logical bitstream.

=head2 C<time_total ([$stream])>

Returns the total number of seconds in the physical bitstream or the
specified logical bitstream.

=head2 C<raw_tell ()>

Returns the current offset in bytes.

=head2 C<pcm_tell ()>

Returns the current offset in pcm samples.

=head2 C<time_tell ()>

Returns the current offset in seconds.

=head1 REQUIRES

Inline::C, libogg, libvorbis, libogg-dev, libvorbis-dev

=head1 AUTHOR

Dan Pemstein E<lt>dan@lcws.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, Dan Pemstein.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at
your option) any later version.  A copy of this license is included
with this module (LICENSE.GPL).

=head1 SEE ALSO

L<Ogg::Vorbis::Header>, L<Inline::C>, L<Audio::Ao>.

=cut

__C__

#include <stdio.h>
#include <string.h>
#include <vorbis/codec.h>
#include <vorbis/vorbisfile.h>

SV* _new(char *class, char *path)
{
	/* A few variables */
	FILE *fd;
	OggVorbis_File *vf =
		(OggVorbis_File *) malloc (sizeof(OggVorbis_File));

	/* Create our new hash and a ref to it */
	HV *hash = newHV();
	SV *obj_ref = newRV_noinc((SV*) hash);

	/* Open the vorbis stream file */
	if ((fd = fopen(path, "r")) == NULL)
		return &PL_sv_undef;
	
	/*if (ov_test(fd, vf, NULL, 0) < 0) {
		fclose(fd);
		return &PL_sv_undef;
	}*/

	if (ov_open(fd, vf, NULL, 0) < 0) {
	/*if (ov_test_open(vf) < 0) {*/
		fclose(fd);
		return &PL_sv_undef;
	}

	/* Values stored at base level */
	hv_store(hash, "PATH", 4, newSVpv(path, 0), 0);
	hv_store(hash, "VFILE", 5, newSViv((IV) vf), 0);
	hv_store(hash, "BSTREAM", 7, newSViv(0), 0);

	/* Bless the hashref to create a class object */
	sv_bless(obj_ref, gv_stashpv(class, FALSE));

	return obj_ref;
}

long _read(	SV* obj, SV *buffer, int buffsize, int bigendianp,
						int word, int sgned)
{
	OggVorbis_File *vf;
	int cbs;
	int res;
	SV *buffdr;
	char buffptr[buffsize];
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));
	cbs = (int) SvIV(*(hv_fetch(hash, "BSTREAM", 7, 0)));

	res = ov_read(vf, buffptr, buffsize, bigendianp, word, sgned, &cbs);
	
	sv_setiv(*hv_fetch(hash, "BSTREAM", 7, 0), (IV) cbs);
	buffdr = (SV *) SvRV(buffer);
	sv_setpvn(buffdr, buffptr, res);
	return res;
}

int _raw_seek (SV* obj, long pos)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));
	
	return ov_raw_seek(vf, pos);
}

int _pcm_seek (SV* obj, ogg_int64_t pos, int page)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));
	
	if (page == 0)
		return ov_pcm_seek(vf, pos);
	else
		return ov_pcm_seek_page(vf, pos);
}

int _time_seek (SV *obj, double pos, int page)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	if (page == 0)
		return ov_time_seek(vf, pos);
	else
		return ov_time_seek_page(vf, pos);
}

long _bitrate (SV* obj, int i)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_bitrate(vf, i);
}

long bitrate_instant (SV* obj)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_bitrate_instant(vf);
}

long streams (SV* obj)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_streams(vf);
}

long seekable (SV* obj)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_seekable(vf);
}

long _serialnumber (SV* obj, int i)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_serialnumber(vf, i);
}

IV _raw_total (SV* obj, int i)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return (IV) ov_raw_total(vf, i);
}

IV _pcm_total (SV* obj, int i)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return (IV) ov_pcm_total(vf, i);
}

double _time_total (SV* obj, int i)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_time_total(vf, i);
}

IV _raw_tell (SV* obj)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return (IV) ov_raw_tell(vf);
}

IV _pcm_tell (SV* obj)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return (IV) ov_pcm_tell(vf);
}

double _time_tell (SV* obj)
{
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);
	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));

	return ov_time_tell(vf);
}

void DESTROY (SV *obj) {
	OggVorbis_File *vf;
	HV *hash = (HV *) SvRV(obj);

	vf = (OggVorbis_File *) SvIV(*(hv_fetch(hash, "VFILE", 5, 0)));
	
	ov_clear(vf);
}
