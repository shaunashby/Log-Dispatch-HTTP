#!perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'Log::Dispatch::HTTP' );
}

# Create dispatcher:
my $dispatch1 = Log::Dispatch->new;
my $cb1 = sub { my %p = @_;  return "[[".$p{message}."]]"; };

# Create HTTP dispatcher and add it to the main dispatcher:
$dispatch1->add(Log::Dispatch::HTTP->new(
		    name => 'myWebLogger',
		    min_level => 'info',
		    server => "localhost",
		    actionURL => '/notify',
		    testmode => 1,
		    sessionkey => '2A8B9880B9E99E3FFAA6',
		    callbacks => $cb1
		)
    );

my $output1;
tie *STDOUT, 'Test::Tie::STDOUT', \$output1;
$dispatch1->log( level => 'info', message => 'start_cb1' );
untie *STDOUT;

chomp($output1);
is($output1, 'Log::Dispatch::HTTP Test mode: URL=http://localhost//notify Params: SESSIONKEY=2A8B9880B9E99E3FFAA6&[[start_cb1]]',
     "Log::Dispatch::HTTP correctly handles single callback function." );

# 2:
my $dispatch2 = Log::Dispatch->new;
my $cb2 = sub { my %p = @_;  return uc($p{message}); };

# Create HTTP dispatcher and add it to the main dispatcher:
$dispatch2->add(Log::Dispatch::HTTP->new(
		    name => 'myWebLogger',
		    min_level => 'info',
		    server => "localhost",
		    actionURL => '/notify',
		    testmode => 1,
		    sessionkey => '2A8B9880B9E99E3FFAA6',
		    callbacks => [ $cb1, $cb2 ]
		)
    );

my $output2;
tie *STDOUT, 'Test::Tie::STDOUT', \$output2;
$dispatch2->log( level => 'info', message => 'start_cb2' );
untie *STDOUT;

chomp($output2);
is($output2, 'Log::Dispatch::HTTP Test mode: URL=http://localhost//notify Params: SESSIONKEY=2A8B9880B9E99E3FFAA6&[[START_CB2]]',
     "Log::Dispatch::HTTP correctly handles multiple callback functions." );

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
