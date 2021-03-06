use warnings;
use strict;
use Data::Dumper;
use JSON;
$Data::Dumper::Terse = 1;

my $input_filename = '/root/ashok/input_2.txt';
my $output_filename = '/root/ashok/output.txt';
my $node_info = '/root/ashok/node_info.txt';
my $curl_file = '/root/ashok/payload.json';
my $hostname=`hostname -f`;

=head
my $input_filename = 'C:\TT_GATE\SKF\CURL\input_2.txt';
my $output_filename = 'C:\TT_GATE\SKF\CURL\output.txt';
my $node_info = 'C:\TT_GATE\SKF\CURL\node_info.txt';
my $curl_file = 'C:\TT_GATE\SKF\CURL\payload.json';

my $hostname = "windows desktop";
=cut

chomp($hostname);
my (@linenumber); 
############################################################################
# Read data from node_info.txt
#
############################################################################
my %node_info;
open(DATA, "< $node_info") or die "Couldn't open file file.txt, $!";
while(<DATA>) {
    chomp;  
    if ($_ =~ m/C_SKF$/){
        my @node_detail = split '\|', $_ ;
        $node_info{$node_detail[1]} = 1;  
    }   
}
close(DATA);
#print scalar(keys(%node_info));


############################################################################
# Write first line of all events to firstline_of_all_events.txt
# Identify begin of line number of each events
############################################################################

my (%event,@arr_events,$msg_id,$server_date,$server_time,$node_name);
my ($cam_flag,$cam_str, $event_start_flag,$count) = (0,"",1,0);

open(DATA, "< $input_filename") or die "Couldn't open file $input_filename, $!";
while(<DATA>) {
   my $curr_line = $_;
   chomp($curr_line);
   my @words = split ' ', $curr_line;
   
   if ( ( defined($words[0] )&& $words[0]  =~ /^(\d\d)\/(\d\d)\/(\d\d)/ )  or  ( defined($words[1] )&& $words[1] =~ /^(\d\d)\/(\d\d)\/(\d\d)/ ) ) {
       my $lastindex = $#words;
       $node_name = $words[$lastindex];
       chomp($node_name);
       if ( exists $node_info{$node_name} ){
           $count++;
           $event_start_flag = 1;
           #$event{"node"} = split('\.',$node_name);
           $event{"node"} = $node_name;
           $event{'relatedcihints'} = $node_name;
           $msg_id = int(rand(1000000)) ;
           $event{"msg_id"} = $msg_id;
           $event{"category"} = "Testing SKF";
           $event{"key"} = "11fb0d60-3b8b-7ea-288-$msg_id";          
           $event{'eventsourcesendingserver'} = $node_name;
           $event{'eventsourceexternalid'} = "11fb0d60-3b8b-7ea-288-$msg_id";
           
           if ( $words[0]  =~ /^(\d\d)\/(\d\d)\/(\d\d)/ ) {
               $server_date = $words[0];
               $server_time = $words[1];  
           } elsif( $words[1]  =~ /^(\d\d)\/(\d\d)\/(\d\d)/ ) {
               $server_date = $words[1];
               $server_time = $words[2];
           }
           my ($m,$d,$y) = split('/', $server_date);
           my $etime = $y.'-'.$m.'-'.$d.'T'.$server_time.'Z';
           $event{'eventsourcecreatedtime'} = $etime;
           my $cus_pair= [{
                'name' => 'OML server',
                'value' => "$hostname",
                },
           ];
           $event{'custompairs'} = $cus_pair;
           
       } else {
           $event_start_flag = 0;
       }
   }
   
    $curr_line =~ s/^\s+|\s+$//g;
    if ( $curr_line =~ m/Msg\.Gen\.Node/){
        @words = split (':', $curr_line,2);
        $event{"msg_gen_node"} = $words[1];    
    } elsif ( $curr_line =~ m/^Severity/) {
        @words = split (':', $curr_line,2);
        $words[1] =~ s/^\s+|\s+$//g;
        $words[1] = "warning" if (!($words[1]));
        $event{"severity"} = $words[1];    
    } elsif ( $curr_line =~ m/^Application/) {
        @words = split (':', $curr_line,2);
        $event{"application"} = $words[1];     
    } elsif ( $curr_line =~ m/^Object/) {
        @words = split ':', $curr_line;
        $event{"object"} = $words[1];       
    } elsif ( $curr_line =~ m/^Message group/) {
        @words = split (':', $curr_line,2);
        #$event{"message_group"} = $words[1];      
    } elsif ( $curr_line =~ m/^Message Text/) {     
        @words = split (':', $curr_line,2);
        $words[1] =~ s/'/ /g;
        $words[1] =~ s/"/'/g;
        $words[1] =~ s/^\s+|\s+$//g;
        my $msg_text = ( $words[1] eq "" ) ? "Empty HPOM message" :$words[1];   
        my $msgtext_len = length($words[1]);
        if ($msgtext_len gt 4000) {
            $msg_text = substr($words[1],0,4000);;
        }
        $event{"title"} = "Testing SKF 00$count  " . $msg_text;       
    } elsif ( $curr_line =~ m/^Annotations/){
        $cam_flag = 0;      
    }
    
    if ( $cam_flag ){ 
       ( $cam_str ne "" ) ? $cam_str = $cam_str . ";;" . $curr_line : $cam_str = $curr_line;
    }

    if( $curr_line =~ m/^Custom Message Attributes/){
        $cam_flag = 1;
    }

    if(/^\s*$/){
        $event{"cma"} = $cam_str;
        push(@linenumber, $.);
        while ( my ($key, $value) = each (%event)){
           $value =~ s/^\s+|\s+$//g if defined $value;
           $event{$key} = $value;         
        }
        push( @arr_events,{%event}) if  ( $event_start_flag and  $event{"msg_gen_node"} eq $node_name );
        %event = ();
        $cam_flag = 0;
        $cam_str = "";
        $event_start_flag = 0;
    }
}
close(DATA);

$event{"cma"} = $cam_str;
while ( my ($key, $value) = each (%event)){
   $value =~ s/^\s+|\s+$//g if defined $value;
   $event{$key} = $value;
}
push( @arr_events,{%event} ) if ( $event_start_flag and  $event{"msg_gen_node"} eq $node_name );


#print( "Number of records : ", scalar(@linenumber) + 1,"\n");

my (%ee,@final_arr);
foreach my $event ( @arr_events ){
    if ($event->{'severity'} =~ /Critical/i ) {
        $event->{'incidentImpact'}='1';
    } elsif ($event->{'severity'} =~ /Warning/i ) {
        $event->{'severity'}='Minor';
    }
    delete $event->{'msg_gen_node'};
    delete $event->{'cma'};
    push(@final_arr,$event);
}

print( " Number of Events : ", scalar(@final_arr),"\n");

#Number of events set send in curl
my $set = 2;
my $s = 0;
my $e = $set - 1 ;
my $r = scalar(@final_arr)/($e+1);

foreach (0..$r) {
    if ( $e >= $#final_arr){
        $e = $#final_arr;
    }
    my @temp_event_arr = @final_arr[$s..$e];
    next if ( scalar(@temp_event_arr) == 0);
    $s = $e + 1;
    $e = $e + $set;
    print("temp_event_arr Size : @temp_event_arr \n");


    open(FH, '>', $curl_file) or die "Couldn't open file $curl_file, $!";
    $ee{"EventList"} =  [ @temp_event_arr ]; 
    my $payload = { %ee };
    my $jsonpayload = encode_json($payload);
    my $post_data = Dumper($jsonpayload);
    $post_data =~ s/^'(.*)'$/$1/;
    print FH "$post_data";
    close(FH);


    my $curl_command = 'curl -X POST -v -H "x-apigw-api-id:" -H "Content-Type: application/json" -H "Authorization: Basic dXNlcm1mb211bDE6b2A4RiY7YlF7PUV1LGJ5PUxpO3R1ZFE9YVRvQy41T0I=" -k "https://api.platformdxc-qa.com/eve1-api/dxc/events/R1/create" -d @payload.json';
    my $status = system($curl_command);
    if ($status != 0) {
        if ($? == -1) {
            print "failed to execute: $!\n";
        }
        elsif ($? & 127) {
            printf "child died with signal %d, %s coredump\n",
            ($? & 127), ($? & 128) ? 'with' : 'without';
        }
        else {
            printf "child exited with value %d\n", $? >> 8;
        }
    }  else {
        print "API Send Successfully \n";  
    }
}