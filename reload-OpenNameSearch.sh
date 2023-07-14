#!/bin/bash -e
#For use on existing Nominatim Server created via OpenNameSearch.sh
#Cited, Inc
#Usage: reload-OpenNameSearch.sh [PBF_URL1] ...

#NOTE: Script will drop old nominatim database and import new data.

PBF_URL="${1}";	#get URL from first parameter, https://download.geofabrik.de/europe/liechtenstein-latest.osm.bz2

PROJECT_NAME='nominatim'
 
NM_USER='ntim';	#nominatim website

function import_osm_data(){
		
		pushd /home/${NM_USER}
		
			#13. Loading data into your server
			PBF_FILE="/home/${NM_USER}/${PBF_URL##*/}"
			wget ${PBF_URL}
			chown ${NM_USER}:${NM_USER} ${PBF_FILE}
			
			UPDATE_URL="$(echo ${PBF_URL} | sed 's/latest.osm.pbf/updates/')"
				
			sed -i.save "s|NOMINATIM_REPLICATION_URL=|NOMINATIM_REPLICATION_URL=\"${UPDATE_URL}\"|" .env

			NP=$(grep -c 'model name' /proc/cpuinfo)
			let AVAIL_MEM=$(free -m | grep -i 'mem:' | sed 's/[ \t]\+/ /g' | cut -f4,7 -d' ' | tr ' ' '+')
			let C_MEM=(AVAIL_MEM/4)*3
			
			mkdir -p /var/www/${PROJECT_NAME}
			chown -R ${NM_USER}:${NM_USER} /var/www/${PROJECT_NAME}
		
		su - ${NM_USER} <<EOF
dropdb nominatim
nominatim import -j ${NP} --osm-file ${PBF_FILE} --osm2pgsql-cache ${C_MEM} --project-dir /var/www/${PROJECT_NAME} 2>&1 | tee /tmp/setup.log
EOF
		
		rm -f ${PDB_FILE}
	popd
	
	chown -R www-data:www-data /var/www/${PROJECT_NAME}
}
 
function init_nm_updates(){
 
	 pushd /home/${NM_USER}
		 nominatim replication --init
	 popd
}
 
#################################

systemctl stop nominatim-updates apache2
rm -rf /var/www/${PROJECT_NAME}
  
import_osm_data;
init_nm_updates;

systemctl start nominatim-updates apache2