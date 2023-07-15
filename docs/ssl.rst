Enable SSL
===========================

Get Certificate
---------------

In order to provision SSL for your instance, follow below:

1. Install the python Cerbot module for Apache::

    apt-get -y install python3-certbot-apache

2. Request certificate::

    certbot --apache --agree-tos --email hostmaster@domain.com --no-eff-email -d domain.com

Be sure to replace 'domain.com' above with your actual domain or sub domain.

Update Configuration
-------------------

You will need to update the Nominatim webapp configuration.

To do so, edit /var/www/html/theme/config.theme.js

Replace:

    Nominatim_Config.Nominatim_API_Endpoint = "http://domain.com/nominatim/"

with:

    Nominatim_Config.Nominatim_API_Endpoint = "https://domain.com/nominatim/"

Restart Apache for update to take effect:

    service apache2 restart


    
