#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Log::Dispatch::HTTP' );
}

diag( "Testing Log::Dispatch::HTTP $Log::Dispatch::HTTP::VERSION, Perl $], $^X" );
