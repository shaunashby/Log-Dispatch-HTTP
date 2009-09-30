package Log::Dispatch::HTTP;

use warnings;
use strict;

=head1 NAME

Log::Dispatch::HTTP - A dispatcher module for the Log::Log4perl logging framework which logs messages to a web application.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides logging to a web application within the Log::Log4perl framework. It can be used in the same way as
the other Log::Dispatch modules, for example

	Log::Dispatch::Email
	Log::Dispatch::File

and only in the context of Log::Log4perl. 

The following configuration illustrates how to have messages passed to Log::Dispatch::HTTP. First, set up to use Log::Log4perl for all 
application logging:

	use Log::Log4perl qw(get_logger :levels);

Configure two loggers: one root logger for main application logging to standard output or a log file where all messages at level WARN or above will be dispatched:
	
 	my $logconf=qq/
 	    log4perl.logger.Application=WARN, Log, Screen
 	    /;
	
and a second for the notifications to a web server where an application is listening for requests.

 	$logconf.=qq/
 	    log4perl.logger.Notifications=INFO, Http
 	    /;

Now add the configuration for the root appender modules:
 	
	$logconf.=qq/
		log4perl.appender.Screen=Log::Dispatch::Screen
		log4perl.appender.Screen.stderr=1
		log4perl.appender.Screen.name=pixelisation
		log4perl.appender.Screen.Threshold=Debug
		log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
		log4perl.appender.Screen.layout.ConversionPattern=[ %d %p ]> %m%n
		log4perl.appender.Log=Log::Dispatch::File
		log4perl.appender.Log.filename=pixelisation.log
		log4perl.appender.Log.mode=append
		log4perl.appender.Log.layout=Log::Log4perl::Layout::PatternLayout
		log4perl.appender.Log.layout.ConversionPattern=%d %p> %M - %m%n
	/;	
		
This is the configuration for the notification logger:

	$logconf.=qq/
		log4perl.appender.Http=Log::Dispatch::HTTP
		log4perl.appender.Http.layout=Log::Log4perl::Layout::PatternLayout
		log4perl.appender.Http.layout.ConversionPattern=mode=%m&P1=%X{P1}&P2=%X{P2}&P3=%X{P3}
		log4perl.appender.Http.server=127.0.0.1:3000
		log4perl.appender.Http.actionURL=a\/b\/notifyme
		log4perl.appender.Http.sessionkey=2A8B9880-B1B0-46EB-AE10-B9E99E3FFAA6
    /;
	
In the Http PatternLayout above,

	mode - a switch which can be passed as a parameter to the listening web application so any number of actions can be defined. This will be set to
		   the value of the message passed into the logging method (%m).
		   	
	%X{N} - The value of N is expanded by Log4perl automatically; %X is the pattern for values obtained from the context Log::Log4perl::MDC
			Values should first be stored in the context like this
			
			Log::Log4perl::MDC->put('P1',$value);
	
	server - The server where the application is running.
	
	actionURL - The URL of the action to be requested, receiving the parameters setup in the message via the ConversionPattern.
	
 	sessionkey - An arbitrary key which could be checked on the server-side for elementary client authorisation


The format of the ConversionPattern above is completely arbitrary and can be tailored to suit, depending on what information should be sent to the web application.

Finally, initialise Log::Log4perl in your application:

	Log::Log4perl->init(\$logconf);

and use the root logger via

	my $logger = get_logger("Application");

For notifications, use the logger with the name "Notifications" as configured above and send using the info() level:

	my $notifications = get_logger("Notifications");
	$notifications->info("did something interesting");

In the above example, two loggers have been configured. However, it should also be possible to create a custom level in Log::Log4perl and have all notifications handled
like this

	$logger->custom_("message to custom function");
	
with only one root logger.


=cut

use LWP::UserAgent;

use Log::Dispatch::Output;
use base qw(Log::Dispatch::Output);

=item C<new(%param)>

Constructor. Not used directly but internally via the Log::Log4perl::Appender configuration.
	
=cut

sub new() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self= bless {} => $class;
	my (%param) = @_;
	
	$self->_basic_init(%param);
	$self->_init(%param);
	
	return $self;
}

=item C<_init(%param)>

Internal initialisation method. Read and store configuration information.

=cut

sub _init() {
	my $self = shift;
	my (%param) = @_;
	
	# Get needed parameters from the Log4perl configuration:
	map {
		$self->{uc($_)} = $param{$_};
	} keys %param;

	# Set min and max levels. We're only interested in INFO
	# messages so everything else can be ignored. This is 
	# actually less important now that we're using a separate
	# Notifications category and logger:
	$self->{min_level} = 1;
	$self->{max_level} = 1;
	# Build the URL
	$self->{URL} = sprintf("http://%s/%s",$self->{SERVER},$self->{ACTIONURL});	
	# Create user agent:
	do {
		$self->{UA} = LWP::UserAgent->new;
		$self->{UA}->agent(__PACKAGE__."/$VERSION\n");
		$self->{UA}->timeout(30); # Just in case server goes bye-byes
	} unless (defined($self->{UA}));

}

=item C<log_message(%param)>

Overrides the logging method in Log::Dispatch::Output. Called automatically by the loggers.

=cut

sub log_message() {
	my $self = shift;
	my (%param) = @_;
	# Request parameters. The message string is created by the Log4perl infrastructure
	# (PatternLayouts and the values in the MDC):
	$self->{PARAMS} = sprintf("SESSIONKEY=%s&%s",$self->{SESSIONKEY},$param{message});
	# Create an HTTP request and POST to the server
	my $req = HTTP::Request->new(POST => $self->{URL});
    $req->content_type('application/x-www-form-urlencoded');
    # Set the parameters for the POST request:
    $req->content($self->{PARAMS});
    # Pass request to the user agent and get a response back:
    my $res = $self->{UA}->request($req);

    if (!$res->is_success) {
		print STDERR __PACKAGE__.": Problem sending notification to ".$self->{SERVER}.".\n";
		print STDERR __PACKAGE__.": ".$res->status_line."\n";
    }
}

=back

=head1 AUTHOR

"Shaun ASHBY", C<< <"Shaun.Ashby at unige.ch"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-dispatch-http at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-HTTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::HTTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-HTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-HTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-HTTP>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-HTTP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 "Shaun ASHBY", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Log::Dispatch::HTTP
