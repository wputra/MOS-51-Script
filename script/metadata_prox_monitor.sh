#!/bin/sh
# TJAROSZEWSKI@MIRANTIS [10.07.2014]
# Script verify availability of metadata proxy server in namespaces

export LC_ALL=C;

RETURNCODE=0;
Q_NUM=0;
Q_NUM_TOTAL=0;

# Creative extension of `ip netns ls | grep -i qrouter | while read r1; do ip netns exec $r1 lsof -i; done`;
QROUTERS_ARRAY=`ip netns ls | grep -i qrouter`;
if [ $? -eq 0 ]; then
        if [ -n "$QROUTERS_ARRAY" ]; then

	for LIST in $QROUTERS_ARRAY; do
                # CHECKING SIZE of QROUTER; MUST BE EQUAL to 45;
                Q_SIZE=`echo $LIST | wc -c`;
                if [ $Q_SIZE -eq 45 ]; then
			Q_NUM_TOTAL=$(($Q_NUM_TOTAL+1));
                        ip netns exec $LIST \
			lsof -i | grep -q 'TCP \*:8775 (LISTEN)' && Q_NUM=$((Q_NUM+1)) || echo MISSING: $LIST;
		else
			echo "UNKNOWN: SIZE of QRouter does not match 45 chars";
			exit 1;
                fi
        done
	else
		echo "UNKNOWN: No QRouters present";
		exit 1;
        fi
else
	echo "UNKNOWN: IP Netns command failure OR No QRouters present";
	exit 2;
fi

echo Q_NUM: $Q_NUM;
echo Q_NUM_TOTAL: $Q_NUM_TOTAL;

if [ $Q_NUM -ne $Q_NUM_TOTAL ]; then
	echo "ERROR: $(($Q_NUM_TOTAL-$Q_NUM)) Metadata Proxy server/s is/are offline";
	RETURNCODE=1;
else
	echo "OK: All QRouter's metadata instances are running";
	RETURNCODE=0;
fi

exit $RETURNCODE;
# EOF
