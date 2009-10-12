#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'Log::Dispatch::HTTP' );
}

# Base class dispatcher:
my $dispatch = Log::Dispatch->new;
# Create HTTP dispatcher and add it to the main dispatcher:
$dispatch->add(Log::Dispatch::HTTP->new(
		   name => 'myWebLogger',
		   min_level => 'info',
		   server => "localhost",
		   actionURL => 'notify',
		   testmode => 1,
		   sessionkey => '2A8B9880B9E99E3FFAA6'
	       )
    );

my $output;
tie *STDOUT, 'Test::Tie::STDOUT', \$output;
$dispatch->log( level => 'info', message => 'start' );
untie *STDOUT;
chomp($output);
is($output, 'Log::Dispatch::HTTP Test mode: URL=http://localhost/notify Params: SESSIONKEY=2A8B9880B9E99E3FFAA6&start',
     "Log::Dispatch::HTTP correctly formats HTTP requests." );



# Borrowed from Log::Dispatch test suite with thanks:
package Test::Tie::STDOUT;

sub TIEHANDLE {
    my $class = shift;
    my $self = {};
    $self->{string} = shift;
    ${ $self->{string} } ||= '';
    return bless $self, $class;
}

sub PRINT {
    my $self = shift;
    ${ $self->{string} } .= join '', @_;
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    ${ $self->{string} } .= sprintf($format, @_);
}

1;


