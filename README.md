# OpenNameSearch

![OpenNameSearch](docs/OpenNameSearch-Main.png)

* Project page: https://www.acugis.com/opennamesearch
* Documentation: https://www.acugis.com/opennamesearch/docs/

[![Documentation Status](https://readthedocs.org/projects/opennamesearch/badge/?version=latest)](https://opennamesearch.docs.acugis.com/en/latest/?badge=latest)

This script is for building a Nominatim server with OpenStreetMap data.

Only for use on a clean Ubuntu 22!

Step 1: Get the OpenNameSearch.sh script from GitHub

      wget https://raw.githubusercontent.com/AcuGIS/OpenNameSearch/master/OpenNameSearch.sh

Step 2: Make it executable:

    chmod 755 OpenNameSearch.sh

Step 3: Run the script

## Script usage:

The script accepts a PBF url:

    ./OpenNameSearch.sh  pbf_url

The pbf_url is the complete PBF url from GeoFarbrik

## Examples:

Load Andorra data (one of the smallest data sets, good for testing):

      ./OpenNameSearch.sh https://download.geofabrik.de/europe/isle-of-man-latest.osm.pbf
)
)

## Welcome Page

Once installation completes, navigate to the IP or hostname on your server.

You should see a page as below:

![OpenNameSearch](docs/OpenNameSearch-Main.png)

Click the Search function (or go to domain.com/search.html)

You should see a page as below:

![OpenNameSearch](docs/OpenNameSearch-Search.png)

To test functionality, enter below into the Search box::

	AD500 Andorra la Vella, Andorra

Confirm that results are returned


![OpenNameSearch](docs/Search-Results.png)
	


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
