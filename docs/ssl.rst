Enable SSL
===========================

Check Hostname
---------------

Be sure that your server hostname is properly set.

While you can use Nominatim with only an IP address, if you wish to use SSL, be sure to set the hostname.

You can check using the 'hostname' command

.. code-block:: console
   
   root@suite:~# hostname
   server1

If the full hostname is not set, use hostnamectl to set the full hostname:

.. code-block:: console

   root@suite:~# hostnamectl set-hostname server1.domain.com

Use the hostname command to verify the full hostname is now set:

.. code-block:: console

   root@suite:~# hostname
   server1.domain.com


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


    
