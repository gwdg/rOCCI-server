rOCCI Server - A Ruby OCCI Server
=============================

[![Build Status](https://secure.travis-ci.org/gwdg/rOCCI-server.png)](http://travis-ci.org/gwdg/rOCCI-server)

If you want to use rOCCI-server in a production environment, follow the production instructions for installation and
configuration, otherwise follow the developer instructions for installation and configuration.

Requirements
------------

The following setup is recommended

* usage of the Ruby Version Manger (RVM)
* Ruby >= 1.9.3
* Bundler gem installed (use ```gem install bundler```)

Installation
------------

### Production

Download the latest version from https://github.com/gwdg/rOCCI-server/downloads

Extract file

    tar xzf rOCCI-server-*.tar.bz
    unzip rOCCI-server-*.zip

Install dependencies

    bundle install --deployment

### Developer

Checkout latest version from GIT:

    git clone git://github.com/gwdg/rOCCI-server.git

Change to rOCCI folder

    cd rOCCI-server

Install dependencies

    bundle install

Configuration
-------------

rOCCI-server comes with different backends. Check the `etc` folder for available backends (e.g. dummy, opennebula, ...).
Each backend has an example configuration in a file with the name of the backend and the extension `.json`. Copy one of
those files (e.g. `etc/backend/dummy/dummy.json`) to `etc/backend/default.json` and adapt its content to your setting.

### OpenNebula backend

To use the OpenNebula backend a special server user is required in OpenNebula. To create a user named occi run the
following command in your OpenNebula environment (replace $RANDOM with a secure password!):

     oneuser create occi $RANDOM --driver server_cipher

After copying `etc/backend/opennebula/opennebula.json` to `etc/backend/default.json` you have to adapt the admin and
password attributes in that file to the ones you chose during the user creation.

If you want to use X.509 authentication for your users, you need to create the users in OpenNebula with the X.509 driver.
For a user named `doe` the command may look like this

    oneuser create doe "/C=US/O=Doe Foundation/CN=John Doe" --driver x509

Backend Customization
---------------------

To configure the behaviour of compute, network and storage resource creation, edit the backend specific extensions of
the OCCI model at `etc/backend/$BACKEND/model` (e.g. `etc/backend/dummy/model` for the dummy backend).

To change the predefined resource or OS templates, you can adapt the existing templates in `etc/backend/$BACKEND/templates`
or add new templates. If resource or OS templates are already registered in the backend, they will be automatically
discovered by rOCCI-server.

### OpenNebula backend

If you want to change the actual deployment within OpenNebula you can change the OpenNebula templates in the files in
`etc/backend/opennebula/one_templates`.

To configure OpenNebula resource templates (e.g. small, medium, large, ...) change the files in etc/backend/opennebula/templates .

Usage
-----

rOCCI-server is using passenger to be deployed into a webserver.

#### Passenger

rOCCI-server will work with the default passenger setup even though this setup is not recommended for production. To use
advanced features such as X.509 authentication, you need to set up passenger with a separate Nginx or Apache webserver.
Luckily, this is pretty easy. Detailed instructions can be found in the
[Passenger Documentation](http://www.modrails.com/documentation.html).

To use the standalone passenger with nginx run the following command (and maybe follow the installation steps) and
rOCCI-server is running

    bundle exec passenger start

To install rOCCI-server with RVM and either Nginx or Apache follow the steps below.

#### RVM

Detailed information on setting up and using RVM can be found on the [RVM website](http://rvm.io/).

Install RVM as sudo user (e.g. not root)

    curl -L https://get.rvm.io | sudo bash -s stable

Select a user as a manager, and add him to rvm group - he will be responsible for installing new rubies.

    usermod -a -G rvm $USER

If you intend to manage rOCCI-server from a different user account, you need to run the following command and logout
and login again

    rvm user gemsets

Setup RVM for rOCCI-server (change the ruby version to your favorite one)

    cd rOCCI-server
    rvm install ruby-1.9.3
    rvm --rvmrc --create ruby-1.9.3@rOCCI-server

#### Nginx

Note: If you intend to use several CAs for client certificate validation, you should use Apache as Nginx currently only
allows to configure one CA file to use for client certificate validation.

Let passenger guide you through installing and or configuring Nginx (for apache see below) for you

    bundle exec rvmsudo passenger-install-nginx-module

Edit the Nginx configuration (e.g. `/opt/nginx/conf/nginx.conf`) and insert a new `server` entry for the rOCCI server.
To use SSL you need a valid server certificate and for client verification you need a file containing all CAs you want
to use for verification (there currently seems to be no way to specify multiple CA files for verification). The entry
should look like this (adapt to your settings, especially $USER! and server_name):

        server {
            # change to the server name rOCCI-server should be accessible from
            server_name  localhost;
            # change to the port rOCCI-server should listen on
            listen 443;
            # important, this needs to point to the public folder of your rOCCI-server
            root /home/$USER/rOCCI-server/public;

            ssl on;
            # this should point to your server host certificate
            ssl_certificate /etc/ssl/certs/server.crt;
            # this should point to your server host key
            ssl_certificate_key /etc/ssl/private/server.key;
            # this should point to the Root CAs which should be used for client verification
            ssl_client_certificate /etc/ssl/certs/ca.pem;
            # if you have multiple CAs in the file above, you may need to increase the verify depht
            ssl_verify_depth 10;
            # set to optional, this tells nginx to attempt to verify SSL certificates if provided
            ssl_verify_client optional;

            passenger_enabled on;
            # pass the subject of the client certificate to passenger
            passenger_set_cgi_param SSL_CLIENT_S_DN $ssl_client_s_dn;
        }

You have to start/restart Nginx before you can use rOCCI-server!

#### Apache

Let passenger guide you through installing and or configuring Apache for you

    bundle exec rvmsudo passenger-install-apache2-module

Create a new VirtualHost in the sites-available directory of Apache (e.g. in `/etc/apache2/sites-available/occi-ssl`)
with the following content (adapt to your settings, especially $USER! and ServerName):

    <VirtualHost *:443>
        SSLEngine on
        # for security reasons you may restrict the SSL protocol, but some clients may fail if SSLv2 is not supported
        SSLProtocol all
        # this should point to your server host certificate
        SSLCertificateFile /etc/ssl/certs/server.crt
        # this should point to your server host key
        SSLCertificateKeyFile /etc/ssl/private/server.key
        # directory containing the Root CA certificates and their hashes
        SSLCACertificatePath /etc/ssl/certs
        # set to optional, this tells Apache to attempt to verify SSL certificates if provided
        SSLVerifyClient optional
        # if you have multiple CAs in the file above, you may need to increase the verify depht
        SSLVerifyDepth 10
        # enable passing of SSL variables to passenger
        SSLOptions +StdEnvVars

        ServerName localhost
        # important, this needs to point to the public folder of your rOCCI-server
        DocumentRoot /home/$USER/rOCCI-server/public
        <Directory /home/$USER/rOCCI-server/public>
            Allow from all
            Options -MultiViews
        </Directory>
    </VirtualHost>

You have to start/restart Apache before you can use rOCCI-server!

Updating
--------

If you checked out rOCCI-server from GIT, then you can pull the latest version or a tagged version, update all required
ruby gems using bundler and restart the server by touching the file tmp/restart.txt:

    cd rOCCI-server
    git pull
    bundle install --deployment
    mkdir tmp
    touch tmp/restart.txt

If you have downloaded a new milestone from https://github.com/gwdg/rOCCI-server/downloads the steps are similar:

    tar xzf rOCCI-server-X.tar.bz
    cp rOCCI-server-X rOCCI-server
    cd rOCCI-server
    bundle install --deployment
    mkdir tmp
    touch tmp/restart.txt

Testing
-------

To run the rspec scenario test run

    bundle exec rspec

For manual testing it is recommended to use the OCCI client supplied as part of the rOCCI gem. For more information
visit https://github.com/gwdg/rOCCI#client

Development
-----------

### Code Documentation

[Code Documentation for rOCCI by YARD](http://rubydoc.info/github/gwdg/rOCCI-server/)

### Continuous integration

[Continuous integration for rOCCI by Travis-CI](http://travis-ci.org/gwdg/rOCCI-server/)

### Contribute

1. Fork it.
2. Create a branch (git checkout -b my_markup)
3. Commit your changes (git commit -am "My changes")
4. Push to the branch (git push origin my_markup)
5. [Use GitHubs Pull Requests](https://help.github.com/articles/using-pull-requests/) to submit the code for review