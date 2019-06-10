use IPC::Run3;
use Encode 'encode';
use JSON;
use JSON::Create create_json;
use MIME::Base64;
use Switch;

sub main
{
    my $params = @ARGV[0] ? decode_json(@ARGV[0]) : {};

    my $httpHeaders = $params->{'__ow_headers'};
    my $requestMethod = uc $params->{'__ow_method'} or 'GET';
    my $requestUri = $params->{'__ow_path'} or '/';
    my $scriptPath = '/var/www/index.php';
    my $queryString = $params->{'__ow_query'} or '';

    # get correct body content
    # decode base64 body if it's binary (non-text)
    my $requestBody = '';
    switch ($requestMethod) {
        case "POST" {
            if ((rindex $httpHeaders->{'content-type'}, "text/", 0) >= 0) {
               next;
            }
            $requestBody = decode_base64($params->{'__ow_body'});
        }
        case "GET" {}
        else {
            $requestBody = $params->{'__ow_body'};
        }
    }
    
    # build php environment vars
    my %php_env_vars = (
        'REDIRECT_STATUS' => 200,
        'REQUEST_METHOD' => $requestMethod,
        'SCRIPT_FILENAME' => $scriptPath,
        'SCRIPT_NAME' => '/index.php',
        'PATH_INFO' => '/',
        'SERVER_NAME' => 'MBUELLA',
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'REQUEST_URI' => $requestUri,
        'QUERY_STRING' => $queryString,
        'CONTENT_LENGTH' => length(encode('UTF-8', $requestBody)),
        'HTTPS' => true
    );

    foreach $variable (keys %php_env_vars) {
        $ENV{$variable} = $php_env_vars{$variable};
    }
    
    foreach $headerKey (keys %{$httpHeaders}) {
        $oldKey = $headerKey;
        $headerKey =~ tr/-/_/;
        $ENV{'HTTP_' . uc($headerKey)} = $httpHeaders->{$oldKey};
        $ENV{uc($headerKey)} = $httpHeaders->{$oldKey};
    }

    my %headers = ();
    my %response = ();
    my $body = "";

    # pass input to stdin
    my $in = $requestBody;

    my $status = run3 ["php-cgi", "-f", $scriptPath], \$stdin, \my $stdout, \my $stderr;

    if (!$err) {   
        $statusCode = 200;     
        my $headerString = "";
        ($headerString, %bodyFragments) = split /\r\n\r\n/, $stdout;
        $body = join "\r\n\r\n", %bodyFragments;
        $body =~ s/\r\n\r\n$//;
        my @headerLines = split /\R/, $headerString;
        foreach my $line (@headerLines) {
            my ($key, $val) = split /: /, $line;
            $headers{$key} = $val;
        }
    } else {
        $statusCode = 500;
        $body = $err;
        %headers = (
            'Status' => "500 Internal Server Error",
            'X-Powered-By' => "PHP/7.2.18",
            'Content-type' => "text/html; charset=UTF-8"
        );
    }
    
    %response = (
        statusCode => $statusCode,
        headers => \%headers,
        body => sprintf("%s", $body),
    );

    return create_json(\%response);
}

printf("%s\n", main());
