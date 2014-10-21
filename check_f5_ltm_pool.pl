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
my($VERSION) = '1.00';
my($snmpcmd) = '/usr/bin/snmpget';

my(%pool) = (
		'ltmPoolLbMode' => 		{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.2', 'desc' => 'Load Balancing Algorithm' },
	'ltmPoolMinUpMembers' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.4', 'desc' => 'Minimum Members Up' },
	'ltmPoolMonitorRule' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.17', 'desc' => 'Monitoring Rule' },
	'ltmPoolStatusAvailState' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.2', 'desc' => 'Status' },
	'ltmPoolStatusDetailReason' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.5', 'desc' => 'Status Reason' },
	'ltmPoolActiveMemberCnt' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.8', 'desc' => 'Active Members' },
	'ltmPoolMemberCnt' => 		{'oid' => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.23', 'desc' => 'Members' },
	'ltmPoolStatServerPktsIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.2', 'desc' => 'Packets In', 'uom' => 'c' },
	'ltmPoolStatServerBytesIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.3', 'desc' => 'Bytes In', 'uom' => 'c' },
	'ltmPoolStatServerPktsOut' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.4', 'desc' => 'Packets Out', 'uom' => 'c' },
	'ltmPoolStatServerBytesOut' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.5', 'desc' => 'Bytes Out', 'uom' => 'c' },
	'ltmPoolStatServerMaxConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.6', 'desc' => 'Max Connections' },
	'ltmPoolStatServerTotConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.7', 'desc' => 'Total Connections', 'uom' => 'c' },
	'ltmPoolStatServerCurConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.8', 'desc' => 'Current Connections', 'uom' => '' },
);

my(%member) = (
	'ltmPoolMemberStatServerPktsIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.5', 'desc' => 'Packets In' , 'uom' => 'c' },
	'ltmPoolMemberStatServerBytesIn' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.6', 'desc' => 'Bytes In' , 'uom' => 'c' },
	'ltmPoolMemberStatServerPktsOut' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.7', 'desc' => 'Packets Out' , 'uom' => 'c' },
	'ltmPoolMemberStatServerBytesOut' =>	{'oid' =>  '.1.3.6.1.4.1.3375.2.2.5.4.3.1.8', 'desc' => 'Bytes Out' , 'uom' => 'c' },
	'ltmPoolMemberStatServerMaxConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.9', 'desc' => 'Max Connections'  },
	'ltmPoolMemberStatServerTotConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.10', 'desc' => 'Total Connections' , 'uom' => 'c' },
	'ltmPoolMemberStatServerCurConns' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.11', 'desc' => 'Current Connections' , 'uom' => '' },
	'ltmPoolMemberStatTotRequests' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.19', 'desc' => 'Total Requests', 'uom' => 'c'},
	'ltmPoolMemberStatCurSessions' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.4.3.1.29', 'desc' => 'Current Sessions', 'uom' => ''},
	'ltmPoolMemberStatCurrentConnsPerSec' =>{'oid' =>  '.1.3.6.1.4.1.3375.2.2.5.4.3.1.30', 'desc' => 'Current Connections Per Second', 'uom' => ''},
	'ltmPoolMbrStatusAvailState'  => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.6.2.1.5', 'desc' => 'Status' },
	'ltmPoolMbrStatusDetailReason' => 	{'oid' => '.1.3.6.1.4.1.3375.2.2.5.6.2.1.8', 'desc' => 'Status Reason' },
	
);

my(%ltmPoolLbMode) = (
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
  timeout => 10,
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
		%oidTable = %pool;
		$oidSuffix = "";
	} elsif ($mode eq "Member") {
		%oidTable = %member;
		$oidSuffix = "." . $oidMemberName . "." . $ServicePort;
	} 
	
	foreach my $obj (keys %oidTable) {
		
		my($cmd) = "$snmpcmd -v2c -c $community -m '' -On -Oe $hostname " . $oidTable{$obj}{'oid'} . "." . $oidPoolName . $oidSuffix;
		
		if ($np->opts->verbose) {
		  print STDERR "Running command: \"$cmd\"\n" if ($np->opts->verbose >= 2);
		} else {
		  $cmd .= ' 2>/dev/null';
		}
		
		my(@response) = split(/:/,`$cmd`);
		my($result) = $response[1];
		return 0 if (!defined($result));
		chomp($result);
		$snmpResults{$obj} = $result;
		
		$np->add_perfdata( label => $oidTable{$obj}{'desc'}, value => $result , uom => $oidTable{$obj}{'uom'}  ) if (defined($oidTable{$obj}{'uom'}));
		
		print STDERR "$oidTable{$obj}{'desc'} = $snmpResults{$obj}\n" if ($np->opts->verbose);
		
	}
	
	return 1;

};

if (!$MemberMode) {

	# Learn about the Pool
	if (!&$GetResults("Pool")){
	 $np->nagios_exit('UNKNOWN', "Pool '$PoolName' is unknown");
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
	if (!&$GetResults("Member")){
		$np->nagios_exit('UNKNOWN', "Member '$MemberName' is unknown");
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
	return length($origString) .$oidString;
}




