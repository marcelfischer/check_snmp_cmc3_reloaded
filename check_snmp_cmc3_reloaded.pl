#!/usr/bin/perl

# Autor: Marcel Fischer
#
# Changelog:
# - 26.11.2013 Version 1
#       - First Release
#
# Todo:
# - write pnp template
# - manual warning and critical values
#
# Bugs:


use strict;
use warnings;
use Getopt::Long;
use Net::SNMP;

my $PLUGIN_VERSION="1.0";

# Variables
my $help;
my $version;
my $session;
my $error;
my $hostname = "localhost";
my $community = "public";
my $unit_port = undef;
my $mode = "auto";
my $warning = undef;
my $critical = undef;

my $EXIT_CODE_FINAL;
my $EXIT_STRING_FINAL= "";
my $EXIT_PERFDATA_FINAL = "";
my $result_final = undef;
my $perfdata_final = undef;

my $PORT_COUNT_OID='1.3.6.1.4.1.2606.7.4.1.1.2.0';

Getopt::Long::Configure('bundling');
GetOptions
	("H=s" => \$hostname,
	 "C=s" => \$community,
	 "P=i" => \$unit_port,
	 "M=s" => \$mode,
	 "w=i" => \$warning,
	 "c=i" => \$critical,
	 "h" => \$help,
	 "v" => \$version);

if ($help) {
	help();
	exit 3;
}

if ($version) {
	print "Version: ".$PLUGIN_VERSION."\n";
	exit 3;
}

#OIDs Port Type and Status
my $PORT_TYPE_OID = "1.3.6.1.4.1.2606.7.4.1.2.1.2.".$unit_port;
my $PORT_STATUS_OID="1.3.6.1.4.1.2606.7.4.1.2.1.6.".$unit_port;
my $PORT_NAME_OID="1.3.6.1.4.1.2606.7.4.1.2.1.3.".$unit_port;

#Open SNMP Session
($session, $error) = Net::SNMP->session( -hostname => $hostname,
					 -version => 'snmpv2c',
					 -community => $community,
					);
#Get Port Count
my $PORT_COUNT = $session->get_request(-varbindlist => [ $PORT_COUNT_OID ],);
$PORT_COUNT = $PORT_COUNT->{$PORT_COUNT_OID};

#Check if the port exists
if (($unit_port > $PORT_COUNT) || ($unit_port eq 0)) {
	print "UNKNOWN - this Port does not exist\n";
	$session->close();
	exit 3;
}

#Get the portname
my $PORT_NAME = $session->get_request(-varbindlist => [ $PORT_NAME_OID ],);
$PORT_NAME = $PORT_NAME->{$PORT_NAME_OID};

#Check the port type
my $PORT_TYPE =  $session->get_request(-varbindlist => [ $PORT_TYPE_OID ],);
$PORT_TYPE = $PORT_TYPE->{$PORT_TYPE_OID};

if ($PORT_TYPE eq "CMCIII-PU"){
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_temp($unit_port,$PORT_NAME);
	$EXIT_CODE_FINAL = $EXIT_CODE;
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.$EXIT_STRING;
	$EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL.$EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_CODE) = check_door($unit_port,$PORT_NAME);
	if ($EXIT_CODE_FINAL eq $EXIT_CODE){
		$EXIT_CODE_FINAL=$EXIT_CODE;
	}
	elsif (($EXIT_CODE_FINAL eq "1") && ($EXIT_CODE eq "0")){
		$EXIT_CODE_FINAL=$EXIT_CODE_FINAL;
	}
	elsif (($EXIT_CODE_FINAL eq "2") && ($EXIT_CODE eq "0") || ($EXIT_CODE eq "1")){
		$EXIT_CODE_FINAL=$EXIT_CODE_FINAL;
	}
	elsif (($EXIT_CODE_FINAL eq "0") && ($EXIT_CODE gt "0")){
		$EXIT_CODE_FINAL=$EXIT_CODE;
	}
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
}

if ($PORT_TYPE eq "CMCIII-GAT"){
	print "UNKNOWN - ".$PORT_TYPE." is not a valid sensor\n";
	exit 3;
}
if ($PORT_TYPE eq "CMCIII-HUM"){
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_hum($unit_port,$PORT_NAME);
	$EXIT_CODE_FINAL = $EXIT_CODE;
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.$EXIT_STRING;
	$EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL.$EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_temp($unit_port,$PORT_NAME);
	if ($EXIT_CODE_FINAL eq $EXIT_CODE){
		$EXIT_CODE_FINAL=$EXIT_CODE;
	}
	elsif (($EXIT_CODE_FINAL eq "1") && ($EXIT_CODE eq "0")){
		$EXIT_CODE_FINAL=$EXIT_CODE_FINAL;
	}
	elsif (($EXIT_CODE_FINAL eq "2") && ($EXIT_CODE eq "0") || ($EXIT_CODE eq "1")){
		$EXIT_CODE_FINAL=$EXIT_CODE_FINAL;
	}
	elsif (($EXIT_CODE_FINAL eq "0") && ($EXIT_CODE gt "0")){
		$EXIT_CODE_FINAL=$EXIT_CODE;
	}
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
	$EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;
}

if ($PORT_TYPE eq "CMCIII-SEN"){
	print "UNKNOWN - ".$PORT_TYPE." is an motion sensor, not implemented yet, maybe never\n";
	exit 3;
}

if ($PORT_TYPE eq "CMCIII-UNI"){
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_airflow($unit_port,$PORT_NAME);
	$EXIT_CODE_FINAL = $EXIT_CODE;
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.$EXIT_STRING;
	$EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL.$EXIT_PERFDATA;
}

if ($PORT_TYPE eq "CMCIII-TMP"){
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_temp($unit_port,$PORT_NAME);
	$EXIT_CODE_FINAL = $EXIT_CODE;
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.$EXIT_STRING;
	$EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL.$EXIT_PERFDATA;
}

if ($PORT_TYPE eq "PSM-M16"){
	print "UNKNOWN - ".$PORT_TYPE." is not implemented yet\n";
	exit 3;
}

print $EXIT_STRING_FINAL." | ".$EXIT_PERFDATA_FINAL."\n";
exit $EXIT_CODE_FINAL;

sub check_hum {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;	

	my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".11";
	my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".14";
	my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".13";
	my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".15";
	my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".12";

	my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
	$PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/100;

	my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
	$PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/100;

	my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
	$PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/100;

	my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
	$PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/100;

	my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
	$PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/100;

	if (($PORT_VALUE >= $PORT_HIGHWARN) && ($PORT_VALUE < $PORT_HIGHCRIT)) {
		$EXIT_CODE=1;
		$EXIT_STRING="WARNING - ".$PORT_NAME." Luftfeuchtigkeit ".$PORT_VALUE."%";
		$EXIT_PERFDATA=$PORT_NAME."_Luftfeuchtigkeit=".$PORT_VALUE."%;".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";0;100";
	}
	elsif ($PORT_VALUE >= $PORT_HIGHCRIT) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Luftfeuchtigkeit ".$PORT_VALUE."%";
		$EXIT_PERFDATA=$PORT_NAME."_Luftfeuchtigkeit=".$PORT_VALUE."%;".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";0;100";
	}
	elsif (($PORT_VALUE <= $PORT_LOWWARN) && ($PORT_VALUE > $PORT_LOWCRIT)) {
		$EXIT_CODE=1;
		$EXIT_STRING="WARNING - ".$PORT_NAME." Luftfeuchtigkeit ".$PORT_VALUE."%";
		$EXIT_PERFDATA=$PORT_NAME."_Luftfeuchtigkeit=".$PORT_VALUE."%;".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";0;100";
	}
	elsif ($PORT_VALUE <= $PORT_LOWCRIT) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Luftfeuchtigkeit ".$PORT_VALUE."%";
		$EXIT_PERFDATA=$PORT_NAME."_Luftfeuchtigkeit=".$PORT_VALUE."%;".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";0;100";
	}
	else {
		$EXIT_CODE=1;
		$EXIT_STRING="OK - ".$PORT_NAME." Luftfeuchtigkeit ".$PORT_VALUE."%";
		$EXIT_PERFDATA=$PORT_NAME."_Luftfeuchtigkeit=".$PORT_VALUE."%;".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";0;100";
	}

	return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);

}

sub check_temp {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;	

	my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".2";
	my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".5";
	my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".4";
	my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".6";
	my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".3";

	my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
	$PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/100;

	my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
	$PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/100;

	my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
	$PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/100;

	my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
	$PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/100;

	my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
	$PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/100;

	if (($PORT_VALUE >= $PORT_HIGHWARN) && ($PORT_VALUE < $PORT_HIGHCRIT)) {
		$EXIT_CODE=1;
		$EXIT_STRING="WARNING - ".$PORT_NAME." Temperatur ".$PORT_VALUE."C";
		$EXIT_PERFDATA=$PORT_NAME."_Temperatur=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	elsif ($PORT_VALUE >= $PORT_HIGHCRIT) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Temperatur ".$PORT_VALUE."C";
		$EXIT_PERFDATA=$PORT_NAME."_Temperatur=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	elsif (($PORT_VALUE <= $PORT_LOWWARN) && ($PORT_VALUE > $PORT_LOWCRIT)) {
		$EXIT_CODE=1;
		$EXIT_STRING="WARNING - ".$PORT_NAME." Temperatur ".$PORT_VALUE."C";
		$EXIT_PERFDATA=$PORT_NAME."_Temperatur=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	elsif ($PORT_VALUE <= $PORT_LOWCRIT) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Temperatur ".$PORT_VALUE."C";
		$EXIT_PERFDATA=$PORT_NAME."_Temperatur=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	else {
		$EXIT_CODE=1;
		$EXIT_STRING="OK - ".$PORT_NAME." Temperatur ".$PORT_VALUE."C";
		$EXIT_PERFDATA=$PORT_NAME."_Temperatur=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}

	return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);

}

sub check_airflow {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;	

	my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".2";
	my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".5";
	my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".4";
	my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".6";
	my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".3";

	my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
	$PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};

	my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
	$PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID};

	my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
	$PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID};

	my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
	$PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID};

	my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
	$PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID};

	if (($PORT_VALUE >= $PORT_HIGHWARN) && ($PORT_VALUE < $PORT_HIGHCRIT)) {
		$EXIT_CODE=1;
		$EXIT_STRING="WARNING - ".$PORT_NAME." Airflow ".$PORT_VALUE."";
		$EXIT_PERFDATA=$PORT_NAME."_Airflow=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	elsif ($PORT_VALUE >= $PORT_HIGHCRIT) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Airflow ".$PORT_VALUE."";
		$EXIT_PERFDATA=$PORT_NAME."_Airflow=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	elsif (($PORT_VALUE <= $PORT_LOWWARN) && ($PORT_VALUE > $PORT_LOWCRIT)) {
		$EXIT_CODE=1;
		$EXIT_STRING="WARNING - ".$PORT_NAME." Airflow ".$PORT_VALUE."";
		$EXIT_PERFDATA=$PORT_NAME."_Airflow=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	elsif ($PORT_VALUE <= $PORT_LOWCRIT) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Airflow ".$PORT_VALUE."";
		$EXIT_PERFDATA=$PORT_NAME."_Airflow=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}
	else {
		$EXIT_CODE=0;
		$EXIT_STRING="OK - ".$PORT_NAME." Airflow ".$PORT_VALUE."";
		$EXIT_PERFDATA=$PORT_NAME."_Airflow=".$PORT_VALUE.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	}

	return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}

sub check_door {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	
	my $EXIT_CODE;
	my $EXIT_STRING;
	my $EXIT_PERFDATA;	

	my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".14";

	my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
	$PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};

	if ($PORT_VALUE == 12) {
		$EXIT_CODE=2;
		$EXIT_STRING="CRITICAL - ".$PORT_NAME." Door is open";
	}
	else {
		$EXIT_CODE=0;
		$EXIT_STRING="OK - ".$PORT_NAME." Door is closed";
	}

	return ($EXIT_STRING,$EXIT_CODE);
}
sub help {
	print "This plugin checks the phoenix contact pmm-ma600 devices over modbus tcp\n";
	print "You need to have an ethernet module and you need to active modbus tcp on your device\n\n";
	print "Version = ".$PLUGIN_VERSION."\n";
	
	print "Usage:\n\n";
	print "-h	print help\n";
	print "-H	Hostname or IP\n";
	print "-C	SNMP Community\n";
	print "-P	Unit Port\n";
	print "-M	Mode\n";

	print "Modes:\n";
	print "Auto,...\n\n";

}
