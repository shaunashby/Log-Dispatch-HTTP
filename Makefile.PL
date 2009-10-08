use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Dispatch::HTTP',
    AUTHOR              => '"Shaun ASHBY" <"Shaun.Ashby@gmail.ch">',
    VERSION_FROM        => 'lib/Log/Dispatch/HTTP.pm',
    ABSTRACT_FROM       => 'lib/Log/Dispatch/HTTP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'Log::Dispatch::Output' => 0,
        'HTTP::Request' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Dispatch-HTTP-*' },
);
