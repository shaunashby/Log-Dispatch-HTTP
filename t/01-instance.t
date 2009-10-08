#!perl

use Test::More tests => 1;

BEGIN {
	    use_ok( 'Log::Log4perl' );
        use_ok( 'Log::Dispatch::HTTP' );
}

my $n = Log::Dispatch::HTTP->new( );

ok(defined($n) && ref($n) eq 'Log::Dispatch::HTTP',"Construction works");

