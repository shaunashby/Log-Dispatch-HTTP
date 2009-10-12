#!perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'Log::Dispatch::HTTP' );
}

# Configuration for appenders:
use Log::Log4perl qw(get_logger :levels);

my $logconf.=qq/
log4perl.logger.myWebLogger=ALL,Http
log4perl.appender.Http=Log::Dispatch::HTTP
log4perl.appender.Http.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.Http.layout.ConversionPattern=mode=%m&PAR1=%X{PAR1}
log4perl.appender.Http.server=localhost
log4perl.appender.Http.actionURL=notify
log4perl.appender.Http.testmode=1
/;

Log::Log4perl->init(\$logconf);

# Get my logger:
my $logger=get_logger('myWebLogger');

ok(defined($logger),"Log4perl setup OK. myWebLogger configured correctly.");

# Setup parameters defined by ConversionPattern:
my $value="P1L4P";
Log::Log4perl::MDC->put('PAR1',$value);

my $output;
tie *STDOUT, 'Test::Tie::STDOUT', \$output;
$logger->info('start_log4perl');
untie *STDOUT;
chomp($output);
is($output, 'Log::Dispatch::HTTP Test mode: URL=http://localhost/notify Params: SESSIONKEY=NULL&mode=start_log4perl&PAR1=P1L4P',
"Log::Dispatch::HTTP correctly formats HTTP requests and works correctly within Log::Log4perl." );


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


