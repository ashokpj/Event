use warnings;
use strict;
use Data::Dumper;


my $input_filename = 'C:\TT_GATE\SKF\CURL\input_2.txt';
my $output_filename = 'C:\TT_GATE\SKF\CURL\output.txt';
my $node_info = 'C:\TT_GATE\SKF\CURL\node_info.txt';

#my $hostname=`hostname -f`;
my $hostname = "windows desktop";
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

my (%event,@arr_events,$msg_id,$server_date,$server_time, $node_name);
my $event_start_flag = 1;
my ($cam_flag,$cam_str) = ( 0,"");
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
		   $event_start_flag = 1;
		   #$event{"node"} = split('\.',$node_name);
		   $event{"node"} = $node_name;
		   $event{'relatedcihints'} = $node_name;
           $msg_id = int(rand(1000000))	;
           $event{"msg_id"} = $msg_id;
		   $event{"category"} = "SKF";
		   $event{"key"} = '11fb0d60-3b8b-7ea-288-ca81e0000';
		   
		   $event{'eventsourcesendingserver'} = $node_name;
		   $event{'eventsourceexternalid'} = '11fb0d60-3b8b-7ea-288-ca81e0000';

		   if ( $words[0]  =~ /^(\d\d)\/(\d\d)\/(\d\d)/ ) {
			   $server_date = $words[0];
			   $server_time = $words[1];  
		   } elsif( $words[1]  =~ /^(\d\d)\/(\d\d)\/(\d\d)/ ) {
			   $server_date = $words[1];
			   $server_time = $words[2];
		   }
		   my ($m,$d,$y)=split('/', $server_date);
           my $etime=$y.'-'.$m.'-'.$d.'T'.$server_time.'Z';
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
		my $msg_text = $words[1];		
		my $msgtext_len = length($words[1]);
		if ($msgtext_len gt 4000) {
			$msg_text = substr($words[1],0,4000);;
		}
	    $event{"title"} = $msg_text;	   
    } elsif ( $curr_line =~ m/^Annotations/){
		$cam_flag = 0;		
	}
	
   	if ( $cam_flag ){		
		if( $cam_str ne ""){ 
			$cam_str = $cam_str . ";;" . $curr_line;
		} else {
			$cam_str = $curr_line;
		}
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

#print("@linenumber","\n");
print( "Number of records : ", scalar(@linenumber) + 1,"\n");
my (%ee,@arr);
foreach my $event ( @arr_events ){
	@arr = ();
	delete $event->{'msg_gen_node'};
	delete $event->{'cma'};
	push(@arr,$event);
	$ee{"EventList"} =  \@arr;
	print Dumper(\%ee);
	
}


#print Dumper( \@arr_events );