#!/bin/bash -e
#Version: 1.0.1
#For use on existing Nominatim Server created via OpenNameSearch.sh
#Cited, Inc
#Usage: reload-OpenNameSearch.sh [PBF_URL1] [PBF_URL2] ...

#NOTE: Script will drop old nominatim database and import new data.
 
NM_USER='ntim';	#nominatim website
NM_VER='2.5.1'
 
#Merge multiple pbf files into one, so we can import into Nominatim
function merge_osm_maps(){
	apt-get -y install osmctools
 
	COUNTER=$(echo ${PBF_FILES} | wc -w);
	PIPES=''
	for f in ${PBF_FILES}; do
		if [ $COUNTER -eq 1 ]; then
			PBF_FILE="/home/${NM_USER}/all.pbf"
			osmconvert ${PIPES} ${f} -o=${PBF_FILE}
		else
			mkfifo p${COUNTER}
			PIPES+="p${COUNTER} "
			osmconvert ${f} --out-o5m -o=p${COUNTER} &
 
			let COUNTER=COUNTER-1
		fi
	done
 
	chown ${NM_USER}:${NM_USER} ${PBF_FILE}
	rm ${PIPES}
}
 
function import_osm_data(){
 
	NP=$(grep -c 'model name' /proc/cpuinfo)
	let C_MEM=$(free -m | grep -i 'mem:' | sed 's/[ \t]\+/ /g' | cut -f4,7 -d' ' | tr ' ' '+')-200
	su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim-${NM_VER}
dropdb nominatim
./utils/setup.php --osm-file ${PBF_FILE} --all --osm2pgsql-cache ${C_MEM} 2>&1 | tee setup.log
exit 0
EOF
 
	service apache2 restart
}
 
#################################
 
PBF_FILES=''
 
cd /home/${NM_USER}
 
#download pbf file/s
for f in $@; do
	PBF_URL="$f"
	PBF_FILE="/home/${NM_USER}/${PBF_URL##*/}"
	if [ ! -f ${PBF_FILE} ]; then
		wget ${PBF_URL}
		chown ${NM_USER}:${NM_USER} ${PBF_FILE}
	fi
	PBF_FILES+=" ${PBF_FILE}";
done
 
if [ $# -gt 1 ]; then #if we have more that 1 pbf file
	merge_osm_maps;
fi
 
import_osm_data;
rm ${PBF_FILES}
