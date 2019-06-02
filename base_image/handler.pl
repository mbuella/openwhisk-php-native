use JSON;
use JSON::Create create_json;

sub main
{
    my @params = @ARGV[0] ? decode_json(@ARGV[0]) : {};

    my $output = "Hello world!";

    # logs
    printf("This is an example log message from an arbitrary Perl program!\n");

    # output
    my %response = (
        params => @params,
        msg => $output
    );

    return create_json(\%response);
}

printf("%s\n", main());
