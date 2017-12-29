#!/bin/bash -e
#Version: 2.0.0
#For use on clean Ubuntu 16 only!!!
#Cited, Inc https://www.citedcorp.com
# Ubuntu 16 support by Christopher Flanagan https://www.flana.com
#Usage Example for State of Delaware:
#./OpenNameSearch.sh http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf
#NOTE: It is best to run this via the screen command as it takes some time to finish.

PBF_URL="${1}";	#get URL from first parameter, http://download.geofabrik.de/europe/germany-latest.osm.pbf

NM_USER='ntim';	#nominatim website
NM_PG_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
SITE_DOMAIN=$(hostname -f)

PG_VER='9.5'
PGIS_VER='2.2'

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

    service postgresql start

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

    service postgresql restart
}

function install_prerequisites(){
    sudo apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
        libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev\
        libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev \
        postgresql-server-dev-9.5 postgresql-9.5-postgis-2.2 postgresql-contrib-9.5 \
        apache2 php php-pgsql libapache2-mod-php php-pear php-db \
        php-intl git python-pip python-pyosmium osmosis libboost-python-dev
}

function install_nominatim(){

    #download
    cd /home/${NM_USER}
    git clone --recursive https://github.com/openstreetmap/Nominatim.git

    #compile
    chown -R ${NM_USER}:${NM_USER} Nominatim
    cd Nominatim
    mkdir build
    cd build
    cmake ..
    make

    #customize
    UPDATE_URL="$(echo ${PBF_URL} | sed 's/latest.osm.pbf/updates/')"
    cat >settings/local.php <<EOF
<?php
// Paths
@define('CONST_Postgresql_Version', '${PG_VER}');
@define('CONST_Postgis_Version', '${PGIS_VER}');

// Daily updates
@define('CONST_Osmosis_Binary', '/usr/bin/osmosis');
@define('CONST_Replication_Url', '${UPDATE_URL}');
@define('CONST_Replication_MaxInterval', '40000');      // Process each update separately, osmosis cannot merge multiple updates
@define('CONST_Replication_Update_Interval', '86400');  // How often upstream publishes diffs
@define('CONST_Replication_Recheck_Interval', '900');   // How long to sleep if no update found yet

// Website settings
@define('CONST_Website_BaseURL', 'http://${SITE_DOMAIN}/nominatim/');
EOF

    #Creating postgres accounts
    su - postgres <<EOF
createuser -sd ${NM_USER}
createuser -SDR www-data
psql -c "alter user ${NM_USER} with password '${NM_PG_PASS}'"
EOF

    cd /home/${NM_USER}

    #Nominatim module reading permissions
    chmod +x -R Nominatim
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
<Directory "/home/${NM_USER}/Nominatim/build/website">
  Options FollowSymLinks MultiViews
  AddType text/html   .php
  DirectoryIndex search.php
  Require all granted
</Directory>

Alias /nominatim /home/${NM_USER}/Nominatim/build/website
EOF
    a2enconf nominatim_dir.conf

    su ${NM_USER} <<EOF
 psql -d nominatim -c 'GRANT usage ON SCHEMA public TO "www-data"'
 psql -d nominatim -c 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO "www-data"'
EOF

    service apache2 restart
}

function import_osm_data(){
    cd /home/${NM_USER}
    #13. Loading data into your server
    PBF_FILE="/home/${NM_USER}/${PBF_URL##*/}"
    if [ ! -f ${PBF_FILE} ]; then
        wget ${PBF_URL}
        chown ${NM_USER}:${NM_USER} ${PBF_FILE}
    fi

    NP=$(grep -c 'model name' /proc/cpuinfo)
    let C_MEM=$(free -m | grep -i 'mem:' | sed 's/[ \t]\+/ /g' | cut -f4,7 -d' ' | tr ' ' '+')-200
    su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim/build
wget -O /home/${NM_USER}/Nominatim/data/country_osm_grid.sql.gz http://www.nominatim.org/data/country_grid.sql.gz
./utils/setup.php --osm-file ${PBF_FILE} --all --osm2pgsql-cache ${C_MEM} 2>&1 | tee /tmp/setup.log
exit 0
EOF

    service apache2 restart
}

function enable_nm_updates(){

    sed -i "s/nonexistent/home\/$NM_USER\/.local\/bin\/pyosmium-get-changes/" /home/${NM_USER}/Nominatim/build/settings/settings.php

    su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim/build
pip install --user osmium

./utils/setup.php --index --create-search-indices
./utils/setup.php --create-functions --enable-diff-updates
./utils/update.php --init-updates
exit 0
EOF


    cat >/etc/systemd/system/nominatum-updates.service <<EOF
[Unit]
Description=Nominatum Updates
Documentation=https://github.com/f1ana/OpenNameSearch

[Service]
Type=simple
ExecStart=/bin/su ntim -c '/home/${NM_USER}/Nominatim/build/utils/update.php --import-osmosis-all --no-npi 1>/dev/null 2>&1' &

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable nominatum-updates.service
    systemctl start nominatum-updates.service
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

apt-get -y update

setup_nm_user;
install_prerequisites;
install_postgresql;
install_nominatim;
#download_optional_data;	#uncomment if you want optional data. Adds 30Gb to install size
import_osm_data;
setup_nm_apache;
enable_nm_updates;
#install_housenumber; #uncomment to install Tiger census data.
