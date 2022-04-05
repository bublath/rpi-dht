package RPi::DHT;
use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '1.0';

require XSLoader;
XSLoader::load('RPi::DHT', $VERSION);

sub new {
    my ($class, $pin, $type, $debug) = @_;

    croak "you must supply a pin number\n" if ! defined $pin;

    my $self = bless {}, $class;
    $self->_pin($pin);

    setup();

    $debug=0 unless defined $debug;
	$type=0 unless defined $type;
	$type=0 if ($type == 11);
	#Type=0 is dht11 - !=0 is dht22
	c_conf($debug,$type);

    return $self;
}

sub read {
    my ($self, $retry) = @_;
	my @ret;
	$retry=3 unless defined $retry;
	
	until (defined $ret[0] || --$retry<0) {
		@ret=c_query($self->_pin);
		sleep(2) unless defined $ret[0];
	}
	$ret[0]=$ret[0]/10.0 if defined $ret[0];
	$ret[1]=$ret[1]/10.0 if defined $ret[1];
	return @ret;
}
	
sub temp {
    my ($self, $want) = @_;

    my $temp = undef;
	my $retry=3;

    until (defined $temp || --$retry<0){
        $temp = c_temp($self->_pin);
		sleep(2) if !defined $temp;
    }

    if (defined $want && $want =~ /f/i && defined $temp){
        $temp = $temp * 9 / 5 + 32;
    }
    return $temp/10.0 if defined $temp;
}
sub humidity {
    my $self = shift;

    my $humidity = undef;
	my $retry=3;

    until (defined $humidity || --$retry<0){
        $humidity = c_humidity($self->_pin);
		sleep(2) if !defined $humidity;
    }
    return $humidity/10.0 if defined $humidity;
}
sub cleanup {
    my $self = shift;
    return c_cleanup($self->_pin);
}
sub _pin {
    # set/get the pin number
    if (@_ == 2){
        $_[0]->{pin} = $_[1];
    }
    return $_[0]->{pin};
}
sub DESTROY {
    my $self = shift;
    $self->cleanup;
}
1;
__END__

=head1 NAME

RPi::DHT - Fetch the temperature/humidity from the DHT11/12 hygrometer sensor on
Raspberry Pi

=head1 SYNOPSIS

    use RPi::DHT;

    my $pin = 18;
	my $type = 11;
	my $debug = 1;

    my $env = RPi::DHT->new($pin,$type,$debug);

	my ($temp,$humidity) = $env->read;

=head1 DESCRIPTION

Based on RPi::DHT11 by Steve Bertrand, (steveb@cpan.org)

This module is an interface to the DHT11/22 temperature/humidity sensor when
connected to a Raspberry Pi's GPIO pins. We use the BCM GPIO pin numbering
scheme.
Since DHT11 and DHT22 need a different initialization timing, you need to specify your sensor type as second argument for new when using a DHT22. Default when passing no value is DHT11 (though you can also pass 11).

If you create an L<RPi::WiringPi> object before creating an object in this
class, you can set up the C<RPi::WiringPi> object with whichever pin
numbering scheme you choose, and this module will follow suit. Eg: if you
set C<RPi::WiringPi> to C<wpi> pin scheme, we'll use it here as well. Note,
though, that you MUST create the C<RPi::WiringPi> object before you create one
of this class!

This module requires the L<wiringPi|http://wiringpi.com/> library to be
installed, and uses WiringPi's GPIO pin numbering scheme (see C<gpio readall>
at the command line).

=head1 METHODS

=head2 new($pin, $type, $debug)

Initalizes the object for usage.

Parameters:

    $pin

Mandatory. BCM GPIO pin number for the DHT11/22 sensor's DATA pin..

    $type

Optional: Specify 22 if you're using a DHT22 sensor, or 11 for DHT11. If not set DHT11 is the default.

    $debug

Optional: Bool. True, C<1> to enable debug output, False, C<0> to disable.

=head2 read($retries)

Fetches both temperature and humidity data in one go. This is the recommended way of getting data, if you need both, since there is no way to read just temperature or humidity. So using the "temp" or "humidity" methods below in a row will actually trigger two sensor reads and increase the probability that one of them fails.

Returns: Array of 2 signed floating point numbers or Array of 2 "undef"s in case of read error

Parameters:

    $retries
	
Optional: Reading DHT sensors is not very reliable, so this module is doing 3 read attempts (with 1s waits inbetween) before giving up. This is typically enough, but you can use this setting to set this to a lower or higher value.


=head2 temp('f')

Fetches the current temperature.

Returns a signed floating point number with the temperature, in Celcius by default or "undef" in case of read error.

Parameters:

    'f'

Optional: Send in the string char C<'f'> to receive the temp in Farenheit.

=head2 humidity

Fetches the current humidity.

Returns the current humidity percentage as a floating point number or "undef" in case of read error.

=head2 cleanup

Returns the pin back to default state if it's not already. Called automatically
by C<DESTROY()>.

=head1 ENVIRONMENT VARIABLES

There are a couple of env vars to help prototype and run unit tests when not on
a RPi board.

=head2 RDE_HAS_BOARD

Set to C<1> to tell the unit test runner that we're on a Pi.

=head2 RDE_NOBOARD_TEST

Set to C<1> to tell the system we're not on a Pi. Most methods/functions will
return default (ie. non-live) data when in this mode.

=head1 SEE ALSO

- L<wiringPi|http://wiringpi.com/>, L<WiringPi::API>, L<RPi::WiringPi>

=head1 AUTHOR

Adimarantis (adimarantis@gmail.com)
Original DHT11 by:
Steve Bertrand, (steveb@cpan.org)

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand, 2021 Adimarantis

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
