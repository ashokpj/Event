use strict;
use warnings;

use LWP::UserAgent::Determined;
use HTTP::Request;
use JSON;
use DBD::Oracle;
use DBI;
use POSIX;

my $logfile='/root/ashok/event_API_response.log';
my $failed_call_file='/root/ashok/event_API_failed_payloads.log';

sub LogMessage
{
        my $message = shift;
        my $time = time;        # or any other epoch timestamp
        my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
        my ($sec, $min, $hour, $day,$month,$year) = (localtime($time))[0,1,2,3,4,5,6];
        $year   = $year + 1900;
        $day    = "0" . $day if ($day < 10);
        $hour   = "0" . $hour if ($hour < 10);
        $min    = "0" . $min if ($min < 10);
        $sec    = "0" . $sec if ($sec < 10);
        my $output = "$day $months[$month] $year $hour:$min:$sec : EVMT: $message";
        open(LOG, ">>".$logfile) || die "Can't open log file: ".$logfile." or file not found\n";
        print LOG "$output \n";
        close(LOG);
        return;

}
sub FailedPayload
{
        my $payload=shift;
        open(FH,">>".$failed_call_file) || LogAndDie("ERROR: Can't open log file: ".$failed_call_file." or $!");
        print FH "$payload\n";
        close(FH);
        return;
}

my $json = JSON->new->utf8;
my $eventlist = ' {
            "eventsourcesendingserver":"pln-n1-hpreport.resrc.entsvcs.com",
            "object":"SRAOML",
            "relatedcihints":"PLN:SQL:pln-n1.resrc.entsvcs.com",
            "application":"MSSQL",
            "node":"pln-n1-hpreport.resrc.entsvcs.com",
            "eventsourcecreatedtime":"2020-01-23T10:45:05Z",
            "key":"11fb0d60-3b8b-7ea-288-ca81e0000",
            "eventsourceexternalid":"11fb0d60-3b8b-71ea-0288-c055a81e0000",
            "custompairs":
                [
                    {
                        "value":"plnn1om00p.env01.mcloud.entsvcs.net",
                        "name":"OML server"
                    },
                    {
                        "value":"condition_name",
                        "name":"OML CMA"
                    }
                ],
            "title":"Testing : 19-Jan-21 OML to OMi - TT-Gate",
            "category":"SRAOML",
            "severity":"critical"
       }
    ';
my $eventlista=[$eventlist];
my $payload={'EventList' => $eventlista};

my $jsonpayload=encode_json($payload);
#print $jsonpayload;

my $post_data=$jsonpayload;

my $userAgent = LWP::UserAgent::Determined->new( cookie_jar => '' );
my $timing_string = $userAgent->timing("5,10,20");
my $http_codes_hr = $userAgent->codes_to_determinate();
#################
#Error HTTP codes
##################
#400 Bad request
#401 Authorization information
#404 Endpoint was not found
#429 AWS throttling limit has been exceeded
#500 Unexpected error

$http_codes_hr->{404} = 1;
$http_codes_hr->{429} = 1;
$http_codes_hr->{500} = 1;


$userAgent->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00 );
#my $host=$configv{'host'};
my $host = "https://api.platformdxc-qa.com/eve1-api/dxc/events/R1";
#my $auth = 'Basic dXNlcm1mb211bDE6b2A4RiY7YlF7PUV1LGJ5PUxpO3R1ZFE9YVRvQy41T0I=';
my $auth = 'dXNlcm1mb211bDE6b2A4RiY7YlF7PUV1LGJ5PUxpO3R1ZFE9YVRvQy41T0I=';
my $x_apigw_api_id = "";

my $req =HTTP::Request->new('POST',$host);;
$req->header('Content-Type' => 'application/json' );
#$req->header('Authorization' => $configv{'auth'});
$req->header('Authorization' => $auth);
#$req->header('x-apigw-api-id' => $configv{'x-apigw-api-id'});
$req->header('x-apigw-api-id' => $x_apigw_api_id);
$req->header('Accept' => 'application/json' );
$req->content($post_data);
print(" Before Post Data \n");
my $response=$userAgent->request($req);
print(" After Post Data \n");

#print LogMessage(Dumper($payload));
print LogMessage("Event API request:");
print LogMessage("$jsonpayload");

if ($response->is_success) {
	print("Succcess");
	my $rescode=decode_json($response->content());
	my $newcon=encode_json($rescode);
	my $resUID=$rescode->[0]->{'uuid'};
	print LogMessage("Event API response UUID: $resUID");
	print LogMessage($newcon);
} else {
	print("Failed");
	my $errorline=$response->status_line;
	print("Failed  : $errorline \n");
	print FailedPayload($jsonpayload);
	print LogMessage("ERROR: TT_gate Event Payload failed, reason=$errorline, payload=$jsonpayload");
}
1;