#!/usr/bin/perl
#
#   Check F5 LTM 11 Pool & Member Performance Metrics
##
#   Copyright (C) 2014 Jay Greenberg <ccie11021@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>..
##

use strict;
use warnings;

use Nagios::Plugin;

my($PROGNAME) = 'check_f5_ltm_pool.pl';
my($VERSION) = '1.01';
my($snmpcmd) = '/usr/bin/snmpget';

# - Items with no 'default' value are required (plugin will not continue if value is not retrieved
# - items with no 'uom' value are not counted as performance metric

my(%pool) = (
	'ltmPoolLbMode' => 		{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.2', 'desc' => 'Load Balancing Algorithm', 'default' => -1  },
	'ltmPoolMinUpMembers' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.4', 'desc' => 'Minimum Members Up', 'default' => 0  },
	'ltmPoolMonitorRule' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.17', 'desc' => 'Monitoring Rule', 'default' => ""  },
	'ltmPoolStatusAvailState' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.2', 'desc' => 'Status' },
	'ltmPoolStatusDetailReason' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.5', 'desc' => 'Status Reason', 'default' => "" },
	'ltmPoolActiveMemberCnt' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.8', 'desc' => 'Active Members', 'default' => 0 },
	'ltmPoolMemberCnt' => 		{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.23', 'desc' => 'Members', 'default' => 0  },
	'ltmPoolStatServerPktsIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.2', 'desc' => 'Packets In', 'uom' => 'c' , 'default' => 0 },
	'ltmPoolStatServerBytesIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.3', 'desc' => 'Bytes In', 'uom' => 'c' , 'default' => 0 },
	'ltmPoolStatServerPktsOut' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.4', 'desc' => 'Packets Out', 'uom' => 'c' , 'default' => 0 },
	'ltmPoolStatServerBytesOut' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.5', 'desc' => 'Bytes Out', 'uom' => 'c' , 'default' => 0 },
	'ltmPoolStatServerMaxConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.6', 'desc' => 'Max Connections', 'default' => 0  },
	'ltmPoolStatServerTotConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.7', 'desc' => 'Total Connections', 'uom' => 'c' , 'default' => 0 },
	'ltmPoolStatServerCurConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.8', 'desc' => 'Current Connections', 'uom' => '' , 'default' => 0 },
);

my(%member) = (
	'ltmPoolMemberStatServerPktsIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.5', 'desc' => 'Packets In' , 'uom' => 'c' , 'default' => 0 },
	'ltmPoolMemberStatServerBytesIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.6', 'desc' => 'Bytes In' , 'uom' => 'c' , 'default' => 0 },
	'ltmPoolMemberStatServerPktsOut' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.7', 'desc' => 'Packets Out' , 'uom' => 'c' , 'default' => 0 },
	'ltmPoolMemberStatServerBytesOut' =>	{'oid' =>  '.1.3.6.1.4.1.3375.2.2.5.4.3.1.8', 'desc' => 'Bytes Out' , 'uom' => 'c' , 'default' => 0 },
	'ltmPoolMemberStatServerMaxConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.9', 'desc' => 'Max Connections'  , 'default' => 0 },
	'ltmPoolMemberStatServerTotConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.10', 'desc' => 'Total Connections' , 'uom' => 'c' , 'default' => 0 },
	'ltmPoolMemberStatServerCurConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.11', 'desc' => 'Current Connections' , 'uom' => '' , 'default' => 0 },
	'ltmPoolMemberStatTotRequests' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.19', 'desc' => 'Total Requests', 'uom' => 'c', 'default' => 0 },
	'ltmPoolMemberStatCurSessions' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.29', 'desc' => 'Current Sessions', 'uom' => '', 'default' => 0 },
	'ltmPoolMemberStatCurrentConnsPerSec' =>{'oid' =>  '.1.3.6.1.4.1.3375.2.2.5.4.3.1.30', 'desc' => 'Current Connections Per Second', 'uom' => '', 'default' => 0 },
	'ltmPoolMbrStatusAvailState'  => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.6.2.1.5', 'desc' => 'Status' },
	'ltmPoolMbrStatusDetailReason' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.6.2.1.8', 'desc' => 'Status Reason' , 'default' => ""},
	
);

my(%ltmPoolLbMode) = (
	'-1'	=> 'Unknown',
	'0'		=> 'Round Robin',
	'1'		=> 'Ratio - Member',
	'2'		=> 'Lease Connections - Member',
	'3'		=> 'Observed - Member',
	'4'		=> 'Predictive - Member',
	'5'		=> 'Ratio - Node',
	'6'		=> 'Least Connections - Node',
	'7'		=> 'Fastest - Node',
	'8'		=> 'Observed - Node',
	'9'		=> 'Predictive - Node',
	'10'	=> 'Dynamic Ratio',
	'11'	=> 'Fastest App Response',
	'12'	=> 'Least Sessions',
	'13'	=> 'Dynamic Ratio Member',
	'14'	=> 'Sticky Source IP',
	'15'	=> 'Weighted Least Connections - Member',
	'16'	=> 'Weighted Least Connections - Node',
	'17'	=> 'Ratio - Session',
);

my(%availState) = (
	'0'		=> 'None (Error)',
	'1'		=> 'Green (Available)',
	'2'		=> 'Yellow (Not Currently Available)',
	'3'		=> 'Red (Not Available)',
	'4'		=> 'Blue (Availability Unknown)',
	'5'		=> 'Grey (Unlicensed)',
);


my $np = Nagios::Plugin->new(
  usage => "Usage: %s -H <hostname> -C <Community> \n"
	. "\t-P <Pool Name> [-p <Partition Name>] \n"
	. "\t[-M <Member Name> -S <Service Port>] \n"
	. " Don't forget to include the Partition Name in the Pool and Member\n"
	. " Pool Mode Example: ./check_f5_ltm_pool.pl -H 10.1.1.1 -C public -P /Common/MY-POOL \n"
	. " Member Mode Example: ./check_f5_ltm_pool.pl -H 10.1.1.1 -C public -P /Common/MY-POOL -M /Common/My-Member -S 80 -v",
	
  version => $VERSION,
  plugin  => $PROGNAME,
  shortname => uc($PROGNAME),
  blurb => 'Check F5 LTM Pool/Member Status & Performance Metrics',
);

$np->add_arg(
  spec => 'hostname|H=s',
  help => '-H, --hostname=<hostname>',
  required => 1,
);

$np->add_arg(
  spec => 'community|C=s',
  help => '-C, --community=<Community>',
  required => 1,
);

$np->add_arg(
  spec => 'pool|P=s',
  help => "-P, --pool=<Pool Name>\n"
	. "   Pool Name\n",
  required => 1,
);

$np->add_arg(
  spec => 'member|M=s',
  help => "-M, --member=<Member Name>\n"
	. "   Member Name\n",
  required => 0,
);



$np->add_arg(
  spec => 'service|S=s',
  help => "-S, --service=<Service Port>\n"
	. "   Service Port\n",
  required => 0,
);

$np->getopts;

my($hostname) = $np->opts->hostname;
my($community) = $np->opts->community;
my($PoolName) = $np->opts->pool;
my($MemberName) = $np->opts->member;
my($ServicePort) = $np->opts->service;

$np->nagios_exit('UNKNOWN', 'You must specifiy a Service Port (-S) with a Member (-M)')
  if (defined($MemberName) && !defined($ServicePort));
  
my($MemberMode) = defined($MemberName);
alarm $np->opts->timeout;


my($oidPoolName) = str2oid($PoolName);
print STDERR "oidPoolName = $oidPoolName\n" if ($np->opts->verbose >= 2);

my(%snmpResults);
my($oidMemberName);
my($status, $message);

my($GetResults);
$GetResults = sub {

	my($mode) = @_;
	my(%oidTable);
	my($oidSuffix);
	
	if ($mode eq "Pool") {
	    print STDERR "Running in Pool Mode\n" if ($np->opts->verbose);
		%oidTable = %pool;
		$oidSuffix = "";
	} elsif ($mode eq "Member") {
	    print STDERR "Running in Member Mode\n" if ($np->opts->verbose);
		%oidTable = %member;
		$oidSuffix = "." . $oidMemberName . "." . $ServicePort;
	} 
	
    print STDERR sprintf("Converted Pool Name '%s' to OID as: %s \n", $PoolName, $oidPoolName ) if ($np->opts->verbose >= 2);

	
	foreach my $obj (sort keys %oidTable) {
		
		my($fulloid) = $oidTable{$obj}{'oid'} . "." . $oidPoolName . $oidSuffix;
		my($cmd) = "$snmpcmd -v2c -c $community -m '' -On -Oe $hostname " . $fulloid;
		
		if ($np->opts->verbose) {
		  print STDERR sprintf("Checking %s (base oid=%s)\n", $oidTable{$obj}{'desc'}, $oidTable{$obj}{'oid'} ) if ($np->opts->verbose >= 2);
		  print STDERR "Running command: \"$cmd\"\n" if ($np->opts->verbose >= 2);
		} else {
		  $cmd .= ' 2>/dev/null';
		}
		
		my(@response) = split(/:/,`$cmd`,2);
		my($result) = $response[1];
		
		if (!defined($result) && !defined($oidTable{$obj}{'default'})){
			return sprintf("No Data at Required OID: '%s' (%s)",$fulloid,$oidTable{$obj}{'desc'}) ;
		} elsif (!defined($result)){
			$snmpResults{$obj} = $oidTable{$obj}{'default'};
		} else {
			chomp($result);
			$snmpResults{$obj} = $result;
		}
		
		$np->add_perfdata( label => $oidTable{$obj}{'desc'}, value => $snmpResults{$obj} , uom => $oidTable{$obj}{'uom'}  ) if (defined($oidTable{$obj}{'uom'}));
		
		print STDERR "$oidTable{$obj}{'desc'} = $snmpResults{$obj}\n" if ($np->opts->verbose);
		
	}
	
	return "";

};

if (!$MemberMode) {

	# Learn about the Pool
	my($pollResult) = &$GetResults("Pool");
	if ($pollResult){
	 $np->nagios_exit('UNKNOWN', sprintf("%s.  It's possible that Pool '$PoolName' is not valid", $pollResult));
	}
	
	$status = OK;
	
	if ($snmpResults{'ltmPoolStatusAvailState'} != 1){
	 $status = CRITICAL;
	}
	
	$message = sprintf("%s. Active Members: %d/%d (Min:%d). Algo is '%s'.  Monitor Rule is %s. ", 
		$snmpResults{'ltmPoolStatusDetailReason'},
		$snmpResults{'ltmPoolActiveMemberCnt'},
		$snmpResults{'ltmPoolMemberCnt'},
		$snmpResults{'ltmPoolMinUpMembers'},
		$ltmPoolLbMode{$snmpResults{'ltmPoolLbMode'}+0},
		$snmpResults{'ltmPoolMonitorRule'},
	);
	
} else {


	$oidMemberName = str2oid($MemberName);
	
	print STDERR "oidMemberName = $oidMemberName\n" if ($np->opts->verbose >= 2);
			
	# Learn about the Member
	my($pollResult) = &$GetResults("Member");
	if ($pollResult){
	 $np->nagios_exit('UNKNOWN', sprintf("%s.  It's possible that Member '$MemberName' is not valid", $pollResult));
	}
	
	$status = OK;
	
	if ($snmpResults{'ltmPoolMbrStatusAvailState'} != 1){
	 $status = CRITICAL;
	}
	
	$message = sprintf("%s. Current Connections:%d, Total Connections:%d", 
		$snmpResults{'ltmPoolMbrStatusDetailReason'},
		$snmpResults{'ltmPoolMemberStatServerCurConns'},
		$snmpResults{'ltmPoolMemberStatServerTotConns'},
	);
	
}

#SNMP is Complete
alarm(0);

$np->nagios_exit( $status, $message );

sub str2oid{
	my ($origString) = @_;
	my ($oidString) = $origString;
	$oidString =~ s/(.)/sprintf('.%u', ord($1))/eg;
	return length($origString) . $oidString;
}




