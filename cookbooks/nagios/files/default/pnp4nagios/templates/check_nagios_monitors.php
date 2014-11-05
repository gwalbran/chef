<?php
#
# Copyright (c) 2014 IMOS
#

$opt[1] = "--vertical-label \"Percent OK Services\"  --title \"Percent OK Services ($servicedesc)\" ";

$def[1] =  "DEF:var1=$RRDFILE[1]:$DS[1]:AVERAGE " ;
$def[1] .= "AREA:var1#00FF00:\"Percent OK Services \" " ;
$def[1] .= "LINE1:var1#000000:\"\" " ;
$def[1] .= "GPRINT:var1:LAST:\"%3.4lg %s$UNIT[1] LAST \" ";
$def[1] .= "GPRINT:var1:MAX:\"%3.4lg %s$UNIT[1] MAX \" ";
$def[1] .= "GPRINT:var1:AVERAGE:\"%3.4lg %s$UNIT[1] AVERAGE \" ";

$opt[2] = "--vertical-label \"Total Checked Services\"  --title \"Total Checked Services ($servicedesc)\" ";

$def[2] =  "DEF:var1=$RRDFILE[2]:$DS[2]:AVERAGE " ;
$def[2] .= "AREA:var1#00FF00:\"Total Checked Services \" " ;
$def[2] .= "LINE1:var1#000000:\"\" " ;
$def[2] .= "GPRINT:var1:LAST:\"%3.4lg %s$UNIT[1] LAST \" ";
$def[2] .= "GPRINT:var1:MAX:\"%3.4lg %s$UNIT[1] MAX \" ";
$def[2] .= "GPRINT:var1:AVERAGE:\"%3.4lg %s$UNIT[1] AVERAGE \" ";

?>
