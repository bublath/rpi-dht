use strict;
use warnings;
use ExtUtils::MakeMaker;

if (! -f '/usr/include/wiringPi.h' && ! -f '/usr/local/include/wiringPi.h'){
    print "wiringPi is not installed, exiting...\n";
#    exit;
}

WriteMakefile(
    NAME              => 'RPi::DHT',
    VERSION_FROM      => 'lib/RPi/DHT.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/RPi/DHT.pm',
       AUTHOR         => 'Adimarantis <adimarantis@gmail.com>') : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/bublath/rpi-dht/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/bublath/rpi-dht.git',
                web => 'https://github.com/bublath/rpi-dht',
            },
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => 1.302078,
    },
    LIBS              => ['-lwiringPi -lrt'],
    DEFINE            => '',
    INC               => '-I.',
);
