# OpenNameSearch

This script is for building a basic Nominatim server with OpenStreetMap data.

Only for use on a clean Ubuntu 14!

Before proceeding, see <a href="http://opennamesearch.org" target="blank"> OpenNameSearch.org </a> for limitations, etc..

An Ubuntu 16 version has been contributed by @f1ana: https://github.com/f1ana

https://github.com/AcuGIS/OpenNameSearch/blob/master/OpenNameSearch-Ubuntu16.sh


Features
--------

- Load OSM Data
- Load OSM data (city, country, continent or planet).
- Postgres, PostGIS, and osm2pgsql
- Installs Postgres, PostGIS, and osm2pgsql.
- Installs and configures Apache for http or https
- Mapnik, mod_tile, and renderd
- OSM-carto or OSM-bright
- OpenLayer and Leaflet example page.


Installation
------------


Step 1: Get the OpenNameSearch.sh script from GitHub

Step 2: Make it executable:

<code>chmod 755 OpenNameSearch.sh</code>

Step 3: Run the script

Usage
------------

pbf_url: Complete PBF url from GeoFarbrik
  
	./OpenNameSearch.sh  pbf_url


Examples
------------

Load Delware data:

<code>./OpenNameSearch.sh http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf </code>

Welcome Page
------------

Once installation completes, navigate to the IP/nominatim or hostname/nominatim on your server.

You should see a page as below:

![installation complete](http://opennamesearch.org/assets/img/Nominatim-Welcome.jpg)


Loading and Reloading PBFs
--------------------------

You can use our reload-OpenNameSearch.sh script via GitHUB script.

Usage is:
<code>	
./reload-OpenNameSearch.sh [PBF_URL1] [PBF_URL2] ...
</code>

Enable Automatic Updates
------------------------

The script creates an updater service.  In order to enable updates:

<code>
chmod +x /etc/init.d/nominatim_updater
</code>

Credits
-------

[Produced by AcuGIS. We Make GIS Simple](https://www.acugis.com) 

[Cited, Inc. Wilmington, Delaware](https://citedcorp.com)


Contribute
----------

- Issue Tracker: github.com/AcuGIS/OpenNameSearch/issues
- Source Code: github.com/AcuGIS/OpenNameSearch

Support
-------

If you are having issues, please let us know.

License
-------

The project is licensed under the BSD license.
