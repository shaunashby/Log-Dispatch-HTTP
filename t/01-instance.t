#!perl

use Test::More tests => 4;

BEGIN {
    use_ok( 'Log::Log4perl' );
    use_ok( 'Log::Dispatch::HTTP' );
}

# Base class dispatcher:
my $dispatch = Log::Dispatch->new;
ok(defined($dispatch), "Created Log::Dispatch object" );

# HTTP Dispatcher:
my $n = Log::Dispatch::HTTP->new( min_level => 'info', name => 'myLogger' );
ok(defined($n) && ref($n) eq 'Log::Dispatch::HTTP',"Construction of Log::Dispatch::HTTP object works");
