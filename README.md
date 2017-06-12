# OpenNameSearch (Beta)

Live <a href="https://dc.acugis.com" target="_blank"> Demo </a>

This script is for building a basic Nominatim server with OpenStreetMap data.

Only for use on a clean Ubuntu 14!

Before proceeding, see <a href="http://opennamesearch.org" target="blank"> OpenNameSearch.org </a> for limitations, etc..

Step 1: Get the OpenNameSearch.sh script from GitHub

Step 2: Make it executable:

<code>chmod 755 OpenNameSearch.sh</code>

Step 3: Run the script

## Script usage:

<code>./OpenNameSearch.sh  pbf_url</code>

pbf_url: Complete PBF url from GeoFarbrik

## Examples:

Load Delware data:

<code>./OpenNameSearch.sh http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf </code>

## Welcome Page

Once installation completes, navigate to the IP/nominatim or hostname/nominatim on your server.

You should see a page as below:

![installation complete](http://opennamesearch.org/assets/img/Nominatim-Welcome.jpg)


## Loading Additional PBFs, Multiplie PBFs, or Replacing Existing PBFs:

You can use our reload-OpenNameSearch.sh script via GitHUB script.

Usage is:
<code>	
./reload-OpenNameSearch.sh [PBF_URL1] [PBF_URL2] ...
</code>

####  Ena##Eana
The script creates an updater service.  In order to enable updates:
<code>
chmod +x /etc/init.d/nominatim_updater ?
</code>
