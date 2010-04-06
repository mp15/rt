#!/usr/bin/perl

use strict;
use File::Find;

sub wanted {
        -f  && /\.html$/ && $_ !~ /Logout.html$/;
}

my $tests;
BEGIN {
$tests = 4;
find ( sub { wanted() and $tests += 3 } , 'share/html/');
}

use RT::Test tests => $tests, strict => 1;
use HTTP::Request::Common;
use HTTP::Cookies;
use LWP;
use Encode;

my $cookie_jar = HTTP::Cookies->new;


my ($baseurl, $agent) = RT::Test->started_ok;

# give the agent a place to stash the cookies
$agent->cookie_jar($cookie_jar);

# get the top page
my $url = $agent->rt_base_url;
diag "base URL is '$url'" if $ENV{TEST_VERBOSE};
$agent->get_ok($url);

# {{{ test a login
$agent->login(root => 'password');
like( $agent->{'content'} , qr/Logout/i, "Found a logout link");


find ( sub { wanted() and test_get($File::Find::name) } , 'share/html');

sub test_get {
        my $file = shift;

        $file =~ s#^share/html/##;
        diag( "testing $url/$file" ) if $ENV{TEST_VERBOSE};
        $agent->get_ok("$url/$file", "GET $url/$file");
#        ok( $agent->{'content'} =~ /Logout/i, "Found a logout link on $file ");
        ok( $agent->{'content'} !~ /Not logged in/i, "Still logged in for  $file");
        ok( $agent->{'content'} !~ /raw error/i, "Didn't get a Mason compilation error on $file");
}

# }}}

# it's predictable that we will get a lot of warnings because some pages need 
# mandatory arguments, let's not show the warnings 
$agent->get_ok( '/__jifty/test_warnings' );

1;
