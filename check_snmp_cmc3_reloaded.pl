#!/usr/bin/perl

# Autor: Marcel Fischer
#
# Changelog:
# - 26.11.2013 Version 1
#       - First Release
# - 12.12.2013 Version 1.1
# 	- Added support for PSM-M16
# 	- Made some code optimization
# Todo:
# - write pnp template
# - manual warning and critical values
#
# Bugs:


use strict;
use warnings;
use Getopt::Long;
use Net::SNMP;

my $PLUGIN_VERSION="1.1";

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
	$EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
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
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
	$EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
	$EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;
}

if ($PORT_TYPE eq "CMCIII-SEN"){
	print "UNKNOWN - ".$PORT_TYPE." is some sensor, not implemented yet\n";
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
        my $EXIT_CODE;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l1_V($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = $EXIT_CODE;
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL.$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l2_V($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l3_V($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l1_V($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l2_V($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l3_V($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l1_A($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l2_A($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l3_A($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l1_A($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l2_A($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l3_A($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

	($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l1_W($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l2_W($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit1_l3_W($unit_port,$PORT_NAME);
	$EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l1_W($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l2_W($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

        ($EXIT_STRING, $EXIT_PERFDATA, $EXIT_CODE) = check_pmm_circuit2_l3_W($unit_port,$PORT_NAME);
        $EXIT_CODE_FINAL = check_final_exit_code($EXIT_CODE,$EXIT_CODE_FINAL);
        $EXIT_STRING_FINAL = $EXIT_STRING_FINAL.", ".$EXIT_STRING;
        $EXIT_PERFDATA_FINAL = $EXIT_PERFDATA_FINAL." ".$EXIT_PERFDATA;

}

print $EXIT_STRING_FINAL." | ".$EXIT_PERFDATA_FINAL."\n";
exit $EXIT_CODE_FINAL;


sub check_final_exit_code {
	my $EXIT_CODE_TEMP = $_[0];
	my $EXIT_CODE_FINAL = $_[1];
	
        if ($EXIT_CODE_FINAL eq $EXIT_CODE_TEMP){
                $EXIT_CODE_FINAL=$EXIT_CODE_TEMP;
        }
        elsif (($EXIT_CODE_FINAL eq "1") && ($EXIT_CODE_TEMP eq "0")){
                $EXIT_CODE_FINAL=$EXIT_CODE_FINAL;
        }
        elsif (($EXIT_CODE_FINAL eq "2") && ($EXIT_CODE_TEMP eq "0") || ($EXIT_CODE_TEMP eq "1")){
                $EXIT_CODE_FINAL=$EXIT_CODE_FINAL;
        }
        elsif (($EXIT_CODE_FINAL eq "0") && ($EXIT_CODE_TEMP gt "0")){
                $EXIT_CODE_FINAL=$EXIT_CODE_TEMP;
        }
return $EXIT_CODE_FINAL;
}

#Subs
sub check_hum {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	my $EXIT_CODE;
	my $EXIT_WORD;
	my $UNIT="%";
	my $PERFDATA_UNIT="%";
	my $DESC = "Luftfeuchtigkeit";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);

}

sub check_temp {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	my $EXIT_CODE;
	my $EXIT_WORD;
	my $UNIT="C";
	my $PERFDATA_UNIT="";
	my $DESC="Temperatur";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
	return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}

sub check_airflow {
	my $unit_port = $_[0];
	my $PORT_NAME = $_[1];
	my $EXIT_CODE;
	my $EXIT_WORD;
        my $UNIT="%";
        my $PERFDATA_UNIT="%";
        my $DESC="Airflow";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";0;100";
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

sub check_pmm_circuit1_l1_V {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
	my $UNIT = "V";
	my $PERFDATA_UNIT = "";
	my $DESC = "Spannung Circuit 1 L1";
        my $EXIT_CODE;
	my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".17";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".20";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".19";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".21";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".18";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/10;
        my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
        $PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/10;
        my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
        $PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/10;
        my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
        $PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/10;
        my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
        $PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/10;
	
	($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l1_V {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "V";
        my $PERFDATA_UNIT = "";
        my $DESC = "Spannung Circuit 2 L1";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".107";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".110";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".109";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".111";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".108";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/10;
        my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
        $PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/10;
        my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
        $PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/10;
        my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
        $PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/10;
        my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
        $PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/10;

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l2_V {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "V";
        my $PERFDATA_UNIT = "";
        my $DESC = "Spannung Circuit 1 L2";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".26";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".29";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".28";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".30";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".27";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/10;
        my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
        $PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/10;
        my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
        $PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/10;
        my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
        $PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/10;
        my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
        $PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/10;

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l2_V {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "V";
        my $PERFDATA_UNIT = "";
        my $DESC = "Spannung Circuit 2 L2";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".116";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".119";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".118";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".120";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".117";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/10;
        my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
        $PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/10;
        my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
        $PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/10;
        my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
        $PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/10;
        my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
        $PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/10;

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l3_V {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "V";
        my $PERFDATA_UNIT = "";
        my $DESC = "Spannung Circuit 1 L3";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".35";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".38";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".37";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".39";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".36";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/10;
        my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
        $PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/10;
        my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
        $PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/10;
        my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
        $PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/10;
        my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
        $PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/10;

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l3_V {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "V";
        my $PERFDATA_UNIT = "";
        my $DESC = "Spannung Circuit 2 L3";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".125";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".128";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".127";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".129";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".126";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID}/10;
        my $PORT_LOWWARN = $session->get_request(-varbindlist => [ $PORT_LOWWARN_OID ],);
        $PORT_LOWWARN = $PORT_LOWWARN->{$PORT_LOWWARN_OID}/10;
        my $PORT_HIGHWARN = $session->get_request(-varbindlist => [ $PORT_HIGHWARN_OID ],);
        $PORT_HIGHWARN = $PORT_HIGHWARN->{$PORT_HIGHWARN_OID}/10;
        my $PORT_LOWCRIT = $session->get_request(-varbindlist => [ $PORT_LOWCRIT_OID ],);
        $PORT_LOWCRIT = $PORT_LOWCRIT->{$PORT_LOWCRIT_OID}/10;
        my $PORT_HIGHCRIT = $session->get_request(-varbindlist => [ $PORT_HIGHCRIT_OID ],);
        $PORT_HIGHCRIT = $PORT_HIGHCRIT->{$PORT_HIGHCRIT_OID}/10;

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l1_A {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "A";
        my $PERFDATA_UNIT = "";
        my $DESC = "Strom Circuit 1 L1";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".44";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".47";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".46";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".48";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".45";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l1_A {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "A";
        my $PERFDATA_UNIT = "";
        my $DESC = "Strom Circuit 2 L1";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".134";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".137";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".136";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".138";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".135";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l2_A {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "A";
        my $PERFDATA_UNIT = "";
        my $DESC = "Strom Circuit 1 L2";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".53";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".56";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".55";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".57";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".54";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l2_A {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "A";
        my $PERFDATA_UNIT = "";
        my $DESC = "Strom Circuit 2 L2";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".143";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".146";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".145";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".147";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".144";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l3_A {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "A";
        my $PERFDATA_UNIT = "";
        my $DESC = "Strom Circuit 1 L3";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".62";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".65";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".64";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".66";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".63";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l3_A {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "A";
        my $PERFDATA_UNIT = "";
        my $DESC = "Strom Circuit 2 L3";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".152";
        my $PORT_LOWWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".155";
        my $PORT_HIGHWARN_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".154";
        my $PORT_LOWCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".156";
        my $PORT_HIGHCRIT_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".153";
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

        ($EXIT_CODE,$EXIT_WORD) = pmm_threshold_check($PORT_VALUE,$PORT_HIGHCRIT,$PORT_HIGHWARN,$PORT_LOWCRIT,$PORT_LOWWARN);
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";".$PORT_HIGHWARN.";".$PORT_HIGHCRIT.";;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l1_W {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "W";
        my $PERFDATA_UNIT = "";
        my $DESC = "Leistung Circuit 1 L1";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".73";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};
	$EXIT_CODE=0;
	$EXIT_WORD="OK";
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";;;;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l1_W {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "W";
        my $PERFDATA_UNIT = "";
        my $DESC = "Leistung Circuit 2 L1";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".163";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};
        $EXIT_CODE=0;
        $EXIT_WORD="OK";
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";;;;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l2_W {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "W";
        my $PERFDATA_UNIT = "";
        my $DESC = "Leistung Circuit 1 L2";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".74";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};
        $EXIT_CODE=0;
        $EXIT_WORD="OK";
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";;;;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l2_W {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "W";
        my $PERFDATA_UNIT = "";
        my $DESC = "Leistung Circuit 2 L2";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".164";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};
        $EXIT_CODE=0;
        $EXIT_WORD="OK";
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";;;;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit1_l3_W {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "W";
        my $PERFDATA_UNIT = "";
        my $DESC = "Leistung Circuit 1 L3";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".75";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};
        $EXIT_CODE=0;
        $EXIT_WORD="OK";
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";;;;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}
sub check_pmm_circuit2_l3_W {
        my $unit_port = $_[0];
        my $PORT_NAME = $_[1];
        my $UNIT = "W";
        my $PERFDATA_UNIT = "";
        my $DESC = "Leistung Circuit 2 L3";
        my $EXIT_CODE;
        my $EXIT_WORD;
        my $EXIT_STRING;
        my $EXIT_PERFDATA;
        my $PORT_VALUE_OID = "1.3.6.1.4.1.2606.7.4.2.2.1.11.".$unit_port.".165";
        my $PORT_VALUE = $session->get_request(-varbindlist => [ $PORT_VALUE_OID ],);
        $PORT_VALUE = $PORT_VALUE->{$PORT_VALUE_OID};
        $EXIT_CODE=0;
        $EXIT_WORD="OK";
        $EXIT_STRING=$EXIT_WORD." - ".$PORT_NAME." ".$DESC." ".$PORT_VALUE.$UNIT;
        $EXIT_PERFDATA=$PORT_NAME." ".$DESC."=".$PORT_VALUE.$PERFDATA_UNIT.";;;;";
        return ($EXIT_STRING,$EXIT_PERFDATA,$EXIT_CODE);
}

 

sub pmm_threshold_check {
	my $PORT_VALUE = $_[0];
        my $PORT_HIGHCRIT = $_[1];
        my $PORT_HIGHWARN = $_[2];
        my $PORT_LOWCRIT = $_[3];
        my $PORT_LOWWARN = $_[4];
	my $EXIT_CODE;
	my $EXIT_WORD;
        if (($PORT_VALUE >= $PORT_HIGHWARN) && ($PORT_VALUE < $PORT_HIGHCRIT)) {
                $EXIT_CODE=1;
                $EXIT_WORD="WARNING";
        }
        elsif ($PORT_VALUE >= $PORT_HIGHCRIT) {
                $EXIT_CODE=2;
                $EXIT_WORD="CRITICAL";
        }
        elsif (($PORT_VALUE <= $PORT_LOWWARN) && ($PORT_VALUE > $PORT_LOWCRIT)) {
                $EXIT_CODE=1;
                $EXIT_WORD="WARNING";
        }
        elsif ($PORT_VALUE <= $PORT_LOWCRIT) {
                $EXIT_CODE=2;
                $EXIT_WORD="CRITICAL";
        }
        else {
                $EXIT_CODE=0;
                $EXIT_WORD="OK";
        }
	return ($EXIT_CODE,$EXIT_WORD);
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
