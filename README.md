check_snmp_cmc3_reload

Nagios Plugin to check the Ports of an Rittal CMC3 Unit <br>
You just need to define a Port. The Plugin does a auto detection on this port. <br>
The warning and critical values are the user defined vaules on the cmc unit. You can also overwrite these values with -w and -c <br>

Features in Version 1.0: <br>
- Auto Detecton for each port, works only with the types of ports I know <br>
- Get the low and high warning and critical values from the cmc unit <br>
- Usable Types: Temp, Hum, Airflow

Usage: <br>
-H = Hostname or IP <br>
-C = SNMP Community <br>
-P = Unit Port <br>
-t = Mode (auto,temp,hum,...) <br>
-w = Warning <br>
-c = Critical
