# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use warnings;
BEGIN { plan tests => 17 };
use Ogg::Vorbis::Decoder;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

ok(my $ogg = Ogg::Vorbis::Decoder->open("test.ogg"));
my $buffer;
ok($ogg->read(\$buffer));
ok($ogg->bitrate);
ok($ogg->bitrate_instant);
ok($ogg->streams);
ok($ogg->seekable);
ok($ogg->serialnumber);
ok($ogg->raw_total);
ok($ogg->pcm_total);
ok($ogg->time_total);
ok($ogg->raw_tell);
ok($ogg->pcm_tell);
ok($ogg->time_tell);
ok($ogg->raw_seek(0), 0);
ok($ogg->pcm_seek(0), 0);
ok($ogg->time_seek(0.0), 0);
