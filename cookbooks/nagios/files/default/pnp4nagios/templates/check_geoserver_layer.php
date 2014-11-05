<?php
#
# Copyright (c) 2014 IMOS
# Plugin: check_geoserver_layer
#
# Response Time
#

$opt[1] = "--vertical-label \"$UNIT[1]\" --title \"Response Time $hostname / $servicedesc\" ";

$def[1] =  "DEF:var1=$RRDFILE[1]:$DS[1]:AVERAGE " ;
if ($WARN[1] != "") {
    $def[1] .= "HRULE:$WARN[1]#FFFF00 ";
}
if ($CRIT[1] != "") {
    $def[1] .= "HRULE:$CRIT[1]#FF0000 ";
}

$def[1] .= rrd::gradient("var1", "66CCFF", "0000ff", "$NAME[1]");
$def[1] .= "LINE1:var1#666666 " ;
$def[1] .= rrd::gprint("var1", array("LAST","MAX","AVERAGE"), "%6.2lf $UNIT[1]");
?>
