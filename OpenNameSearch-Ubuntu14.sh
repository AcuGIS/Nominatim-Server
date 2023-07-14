#!/bin/bash -e
#Version: 1.0.1
#For use on clean Ubuntu 14 only!!!
#Cited, Inc https://www.citedcorp.com
#Usage Example for State of Delawar:
#./OpenNameSearch.sh http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf
#NOTE: It is best to run this via the screen command as it takes some time to finish.

PBF_URL="${1}";	#get URL from first parameter, http://download.geofabrik.de/europe/germany-latest.osm.pbf
 
NM_USER='ntim';	#nominatim website
NM_PG_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
SITE_DOMAIN=$(hostname -f)
 
PG_VER='9.6'
PGIS_VER='2.3'
NM_VER='2.5.1'
 
function install_postgresql(){
 
	#3. Install PostgreSQL
	echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
	apt-get -y update
 
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
	#NOTE: php7 doesn't work
	apt-get -y install build-essential libxml2-dev libpq-dev libbz2-dev libtool automake libproj-dev \
		libboost-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev libexpat-dev gcc \
		proj-bin libgeos-c1 libgeos++-dev libexpat-dev php5 php-pear php5-pgsql php5-json php-db \
		libapache2-mod-php5 wget osmosis
}
 
function install_nominatim(){
 
	#download
	if [ ! -f /tmp/Nominatim-${NM_VER}.tar.bz2 ]; then
		wget -P/tmp http://www.nominatim.org/release/Nominatim-${NM_VER}.tar.bz2
	fi
	cd /home/${NM_USER}
	tar xvf /tmp/Nominatim-${NM_VER}.tar.bz2
	rm -rf /tmp/Nominatim-${NM_VER}.tar.bz2
 
	#compile
	chown -R ${NM_USER}:${NM_USER} Nominatim-${NM_VER}
	pushd Nominatim-${NM_VER}
	./configure
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
 
	popd
 
	#Nominatim module reading permissions
	chmod +x Nominatim-${NM_VER}
	chmod +x Nominatim-${NM_VER}/module
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
		wget --output-document=data/${f}.sql.bin http://www.nominatim.org/data/${f}.sql.bin
	done
}
 
function setup_nm_apache(){
	mkdir -p /var/www/html/nominatim
	chown ${NM_USER}:${NM_USER} /var/www/html/nominatim
 
	cd /home/${NM_USER}/Nominatim-${NM_VER}
	./utils/setup.php --create-website /var/www/html/nominatim
 
	cat >/etc/apache2/conf-available/nominatim_dir.conf <<EOF
<Directory "/var/www/html/nominatim/">
    Options FollowSymLinks MultiViews
    AddType text/html   .php
</Directory>
EOF
	a2enconf nominatim_dir.conf
	a2enmod php5
 
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
	let AVAIL_MEM=$(free -m | grep -i 'mem:' | sed 's/[ \t]\+/ /g' | cut -f4,7 -d' ' | tr ' ' '+')
	let C_MEM=(AVAIL_MEM/4)*3
	su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim-${NM_VER}
./utils/setup.php --osm-file ${PBF_FILE} --all --osm2pgsql-cache ${C_MEM} 2>&1 | tee setup.log
exit 0
EOF
 
	service apache2 restart
}
 
function enable_nm_updates(){
 
		su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim-${NM_VER}
./utils/setup.php --osmosis-init
./utils/setup.php --create-functions --enable-diff-updates
exit 0
EOF
 
	cat >/etc/init.d/nominatim_updater <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:        nominatim_update
# Required-Start:  \$network
# Required-Stop:   \$network
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: Start/Stop Nominatim update script
### END INIT INFO
 
RETVAL=\$?
 
function start(){
	if [ -z "\${NM_PID}" ]; then
		echo "Starting Nominatim updates"
		/bin/su ntim -c '/home/${NM_USER}/Nominatim-${NM_VER}/utils/update.php --import-osmosis-all --no-npi 1>/dev/null 2>&1' &
	fi
	RETVAL=\$?
}
 
function stop(){
	if [ "\${NM_PID}" ]; then
		echo "Stopping Nominatim updates ..."
		kill -SIGTERM \${NM_PID}
	fi
	RETVAL=\$?
}
 
NM_PID=\$(ps -axww | grep 'update.php --import-osmosis-all' | grep -v 'su ' | grep -v grep | awk '{print \$1}' | tr '\n' ' ');
 
case "\$1" in
 start)
		start;
        ;;
 stop)
		stop;
        ;;
 status)
		if [ "\${NM_PID}" ]; then
			echo "Nominatim updates are running with PID \${NM_PID}";
			RETVAL=1
		else
			echo "Nominatim updates are not running";
			RETVAL=0
		fi
		;;
 *)
        echo \$"Usage: \$0 {start|stop|status}"
        exit 1
        ;;
esac
exit \$RETVAL
EOF
}
 
function install_housenumber(){
	apt-get install -y python-gdal
 
	#11Gb download!
	mkdir -p /home/${NM_USER}/tiger/
	wget -P/home/${NM_USER}/tiger/ ftp://mirror1.shellbot.com/census/geo/tiger/TIGER2015/EDGES/
 
su - ${NM_USER} <<EOF
cd /home/${NM_USER}/Nominatim-${NM_VER}
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
