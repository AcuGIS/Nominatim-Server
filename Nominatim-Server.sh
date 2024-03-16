#!/bin/bash -e
#Version: 3.1.0
#For use on clean Ubuntu 22 only!!!
#Cited, Inc https://www.citedcorp.com
#Usage Example for State of Delaware:
#./Nominatim-Server.sh http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf
#NOTE: It is best to run this via the screen command as it takes some time to finish.

PBF_URL="${1}";	#get URL from first parameter, http://download.geofabrik.de/europe/germany-latest.osm.pbf

PROJECT_NAME='nominatim'

NM_USER='ntim';	#nominatim website
NM_PG_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
HNAME=$(hostname -f)

PG_VER='14'
PGIS_VER='3'

function install_postgresql(){

    #3. Install PostgreSQL
    apt-get install -y	postgresql-${PG_VER} postgresql-client-${PG_VER} postgresql-contrib-${PG_VER} \
        postgresql-server-dev-${PG_VER} postgresql-${PG_VER}-postgis-${PGIS_VER} postgis

    if [ ! -f /usr/lib/postgresql/${PG_VER}/bin/postgres ]; then
        echo "Error: Get PostgreSQL version"; exit 1;
    fi

    ln -sf /usr/lib/postgresql/${PG_VER}/bin/pg_config 	/usr/bin
    ln -sf /var/lib/postgresql/${PG_VER}/main/		 	/var/lib/postgresql
    ln -sf /var/lib/postgresql/${PG_VER}/backups		/var/lib/postgresql

    systemctl start postgresql

    #5. Set postgres Password
    if [ $(grep -m 1 -c 'pg pass' /root/auth.txt) -eq 0 ]; then
        PG_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
        sudo -u postgres psql 2>/dev/null -c "alter user postgres with password '${PG_PASS}'"
        echo "pg pass: ${PG_PASS}" > /root/auth.txt
    fi

    #4. Add Postgre variables to environment
    if [ $(grep -m 1 -c 'PGDATA' /etc/environment) -eq 0 ]; then
        cat >>/etc/environment <<CMD_EOF
export PGDATA=/var/lib/postgresql/${PG_VER}/main
CMD_EOF
    fi

    #6. Configure ph_hba.conf
    cat >/etc/postgresql/${PG_VER}/main/pg_hba.conf <<CMD_EOF
local	all all 							trust
host	all all 127.0.0.1	255.255.255.255	md5
host	all all 0.0.0.0/0					md5
host	all all ::1/128						md5
hostssl all all 127.0.0.1	255.255.255.255	md5
hostssl all all 0.0.0.0/0					md5
hostssl all all ::1/128						md5
CMD_EOF
    sed -i.save "s/.*listen_addresses.*/listen_addresses = '*'/" /etc/postgresql/${PG_VER}/main/postgresql.conf

    #10. Create Symlinks for Backward Compatibility
    mkdir -p /var/lib/pgsql
    ln -sf /var/lib/postgresql/${PG_VER}/main /var/lib/pgsql
    ln -sf /var/lib/postgresql/${PG_VER}/backups /var/lib/pgsql

    systemctl restart postgresql
}

function install_prerequisites(){
    apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
        libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev\
        libbz2-dev libpq-dev liblua5.3-dev lua5.3 libgeos-dev libgeos++-dev libproj-dev \
        postgresql-server-dev-${PG_VER} postgresql-${PG_VER}-postgis-${PGIS_VER} postgresql-contrib-${PG_VER} \
        apache2 php php-{cgi,cli,intl,pgsql,pear,db} libapache2-mod-php \
				libicu-dev python3-{dotenv,psycopg2,psutil,jinja2,icu,datrie,sqlalchemy,asyncpg} \
        git python-pip python3-pyosmium osmosis libboost-python-dev nlohmann-json3-dev
}

function install_nominatim(){
	
    #download
    pushd /home/${NM_USER}
			git clone --recursive https://github.com/openstreetmap/Nominatim.git
			
	    #compile
	    pushd Nominatim
				git checkout v4.4.0
	    	
				wget -O data/country_osm_grid.sql.gz https://www.nominatim.org/data/country_grid.sql.gz
				
				mkdir build
				pushd build
			    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
			    make -j $(grep -c 'processor' /proc/cpuinfo)
					make install
			    chown -R ${NM_USER}:${NM_USER} /home/${NM_USER}/Nominatim
				popd
			popd
		popd
		
    #Creating postgres accounts
    su - postgres <<EOF
createuser -sd ${NM_USER}
createuser -SDR www-data
psql -c "alter user ${NM_USER} with password '${NM_PG_PASS}'"
EOF
}

function install_nominatim_ui(){
	NMUI_VER='3.5.1'
	
	pushd /home/${NM_USER}
	
		wget -P/tmp https://github.com/osm-search/nominatim-ui/releases/download/v${NMUI_VER}/nominatim-ui-${NMUI_VER}.tar.gz
		tar -xf /tmp/nominatim-ui-${NMUI_VER}.tar.gz
		rm -rf /tmp/nominatim-ui-${NMUI_VER}.tar.gz
		
		pushd nominatim-ui-${NMUI_VER}
			mv dist/theme/config.theme.js.example dist/theme/config.theme.js
			sed -i.save "s|Nominatim_Config.Nominatim_API_Endpoint =.*|Nominatim_Config.Nominatim_API_Endpoint = \"http://${HNAME}/nominatim/\"|" dist/theme/config.theme.js
		popd


		#Add webapp
  		mv nominatim-ui-${NMUI_VER}/dist/* /var/www/html/
		rm -f /var/www/html/index.html
		wget --quiet -P/tmp https://github.com/AcuGIS/Nominatim-Server/archive/refs/heads/master.zip
		unzip /tmp/master.zip -d/tmp
		cp -r /tmp/Nominatim-Server-master/app/* /var/www/html/
		rm -rf /tmp/master.zip
        	#sed -i.save "s/localhost/${HNAME}/" /var/www/html/leaflet-example.html



  
		chown -R www-data:www-data /var/www/html/
	popd
}

function setup_nm_user(){
    if [ $(grep -cm 1 "^${NM_USER}:" /etc/passwd) -eq 0 ]; then
        useradd -m ${NM_USER}
    fi

    if [ $(grep -m 1 -c "${NM_USER} pass" /root/auth.txt) -eq 0 ]; then
        USER_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
        echo "${NM_USER}:${USER_PASS}" | chpasswd
        echo "${NM_USER} pass: ${USER_PASS}" >> /root/auth.txt
    fi
}

function download_optional_data(){
    for f in wikipedia_article wikipedia_redirect gb_postcode_data; do
        wget --output-document=/home/${NM_USER}/Nominatim/data/${f}.sql.bin http://www.nominatim.org/data/${f}.sql.bin
    done
}

function setup_nm_apache(){

    cat >/etc/apache2/conf-available/nominatim_dir.conf <<EOF
<Directory "/var/www/${PROJECT_NAME}/website">
  Options FollowSymLinks MultiViews
  AddType text/html   .php
  DirectoryIndex search.php
  Require all granted
</Directory>

 Alias /nominatim /var/www/${PROJECT_NAME}/website
EOF
    a2enconf nominatim_dir.conf

    su ${NM_USER} <<EOF
 psql -d nominatim -c 'GRANT usage ON SCHEMA public TO "www-data"'
 psql -d nominatim -c 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO "www-data"'
EOF

    systemctl restart apache2
}

function import_osm_data(){
		
		pushd /home/${NM_USER}
		
			#13. Loading data into your server
			PBF_FILE="/home/${NM_USER}/${PBF_URL##*/}"
			wget ${PBF_URL}
			chown ${NM_USER}:${NM_USER} ${PBF_FILE}
			
			UPDATE_URL="$(echo ${PBF_URL} | sed 's/latest.osm.pbf/updates/')"
			
			cat >.env <<CAT_CMD
# update replication url
NOMINATIM_REPLICATION_URL="${UPDATE_URL}"

# How often upstream publishes diffs (in seconds)
NOMINATIM_REPLICATION_UPDATE_INTERVAL=86400

# How long to sleep if no update found yet (in seconds)
NOMINATIM_REPLICATION_RECHECK_INTERVAL=900

NOMINATIM_DATABASE_DSN="pgsql:dbname=nominatim;user=${NM_USER};password=${NM_PG_PASS}"
CAT_CMD
		
				
		NP=$(grep -c 'model name' /proc/cpuinfo)
		let AVAIL_MEM=$(free -m | grep -i 'mem:' | sed 's/[ \t]\+/ /g' | cut -f4,7 -d' ' | tr ' ' '+')
		let C_MEM=(AVAIL_MEM/4)*3
				
		mkdir /var/www/${PROJECT_NAME}
		chown -R ${NM_USER}:${NM_USER} /var/www/${PROJECT_NAME}
		
		su - ${NM_USER} <<EOF
wget -O /home/${NM_USER}/Nominatim/data/country_osm_grid.sql.gz http://www.nominatim.org/data/country_grid.sql.gz
nominatim import -j ${NP} --osm-file ${PBF_FILE} --osm2pgsql-cache ${C_MEM} --project-dir /var/www/${PROJECT_NAME} 2>&1 | tee /tmp/setup.log
EOF
		
		rm -f ${PBF_FILE}
	popd
	
	chown -R www-data:www-data /var/www/${PROJECT_NAME}
}

function enable_nm_updates(){
	
		pushd /home/${NM_USER}
			nominatim replication --init
		popd
	
    cat >/etc/systemd/system/nominatim-updates.service <<EOF
[Unit]
Description=Nominatum Updates
Documentation=https://github.com/f1ana/OpenNameSearch

[Service]
Type=simple
User=${NM_USER}
Group=${NM_USER}
WorkingDirectory=/home/${NM_USER}/
ExecStart=nominatim replication
StandardOutput=append:/var/log/nominatim-updates.log
StandardError=append:/var/log/nominatim-updates.error.log

[Install]
WantedBy=multi-user.target
EOF
}

function install_housenumber(){
    apt-get install -y python-gdal

    #11Gb download!
    mkdir -p /home/${NM_USER}/tiger/
    wget -P/home/${NM_USER}/tiger/ ftp://mirror1.shellbot.com/census/geo/tiger/TIGER2015/EDGES/

    su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim/build
./utils/imports.php --parse-tiger /home/${NM_USER}/tiger
./utils/setup.php --import-tiger-data
EOF
}

#Check input parameters
if [ -z "${PBF_URL}" ]; then
    echo "Usage: $0 <pbf_url>"; exit 1;
fi

touch /root/auth.txt
export DEBIAN_FRONTEND=noninteractive

apt-get -y update

setup_nm_user;
install_prerequisites;
install_postgresql;
install_nominatim;
install_nominatim_ui;
#download_optional_data;	#uncomment if you want optional data. Adds 30Gb to install size
import_osm_data;
setup_nm_apache;
enable_nm_updates;
#install_housenumber; #uncomment to install Tiger census data.
