use IPC::Run qw(run);
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
    
    # execute php file
    run ["php-cgi", "-f", "index.php"], ">", \my $output;

    # parse response
    my ($headerString, $body) = split /\R\R/, $output;
    my @headerLines = split /\R/, $headerString;
    my %headers = ();
    foreach my $line (@headerLines) {
        my ($key, $val) = split /: /, $line;
        $headers{$key} = $val;
    }
    
    # output
    my %response = (
        statusCode => 200,
        headers => \%headers,
        body => sprintf("%s", $body),
    );

    return create_json(\%response);
}

printf("%s\n", main());
