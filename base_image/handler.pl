use IPC::Run3;
use Encode 'encode';
use JSON;
use JSON::Create create_json;

sub main
{
    my @params = @ARGV[0] ? decode_json(@ARGV[0]) : {};

    my $scriptPath = '/var/www/index.php';
    my $requestBody = '';

    # build php environment vars
    my %php_env_vars = (
        'REDIRECT_STATUS' => 200,
        'REQUEST_METHOD' => 'GET',
        'SCRIPT_FILENAME' => $scriptPath,
        'SCRIPT_NAME' => '/index.php',
        'PATH_INFO' => '/',
        'SERVER_NAME' => 'MBUELLA',
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'REQUEST_URI' => '/',
        'QUERY_STRING' => '',
        'CONTENT_LENGTH' => length(encode('UTF-8', $requestBody)),
        'HTTPS' => true
    );

    foreach $variable (keys %php_env_vars) {
        $ENV{$variable} = $php_env_vars{$variable};
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
        ($headerString, $body) = split /\R\R/, $stdout;
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
