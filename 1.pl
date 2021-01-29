use warnings;
use strict;
use Data::Dumper;
use JSON;
my @arr = (1..2);
my $set = 10;
my $s = 0;
my $e = $set -1 ;
my $r = scalar(@arr)/($e+1);
print("RRRRR: $r \n");
foreach (0..$r){
	if ( $e >= $#arr){
		$e = $#arr;
	}
	my @a = @arr[$s..$e];
	next if ( scalar(@a) == 0);
	$s = $e + 1;
	$e = $e + $set;
	print("Array : @a \n");
}

#!/usr/bin/perl -w
use POSIX;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#$year += 1900;
print "$sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst\n";
my $now_string = localtime; 
print "$now_string\n";

$now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
print "$now_string\n";