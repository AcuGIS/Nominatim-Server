# OpenNameSearch

![OpenNameSearch](docs/OpenNameSearch-Main.png)

* Project page: https://www.acugis.com/opennamesearch
* Documentation: https://www.acugis.com/opennamesearch/docs/

[![Documentation Status](https://readthedocs.org/projects/opennamesearch/badge/?version=latest)](https://opennamesearch.docs.acugis.com/en/latest/?badge=latest)

This script is for building a basic Nominatim server with OpenStreetMap data.

Only for use on a clean Ubuntu 14!

Before proceeding, see <a href="http://opennamesearch.org" target="blank"> OpenNameSearch.org </a> for limitations, etc..

An Ubuntu 16 version has been contributed by @f1ana: https://github.com/f1ana

https://github.com/AcuGIS/OpenNameSearch/blob/master/OpenNameSearch-Ubuntu16.sh

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

Once installation completes, navigate to the IP or hostname on your server.

You should see a page as below:

![installation complete](docs/OpenNameSearch-Main.png)

Click Search to start a search:

![Search Function](docs/OpenNameSearch-Search.png)


## Loading Additional PBFs, Multiplie PBFs, or Replacing Existing PBFs:

You can use our reload-OpenNameSearch.sh script via GitHUB script.

Usage is:
<code>	
./reload-OpenNameSearch.sh [PBF_URL1] ...
</code>

## Enable Automatic Updates

The script creates an updater service.  In order to enable updates:

<code>
systemctl enable nominatim-updates.service
systemctl start nominatim-updates.service
</code>

## Credits

[Produced by AcuGIS. We Make GIS Simple](https://www.acugis.com) 

[Cited, Inc. Wilmington, Delaware](https://citedcorp.com)
