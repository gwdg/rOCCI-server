rOCCI Server - A Ruby OCCI Server
=============================

**rOCCI-server is going through a complete re-design and re-write. Please, do NOT use the master branch for deployment in production or testing environments! Use the stable [0.5.x](https://github.com/gwdg/rOCCI-server/tree/0.5.x) branch as described in [Installation#Production](https://github.com/arax/rOCCI-server#production).**

[![Build Status](https://secure.travis-ci.org/gwdg/rOCCI-server.png)](http://travis-ci.org/gwdg/rOCCI-server) [![Dependency Status](https://gemnasium.com/gwdg/rOCCI-server.png)](https://gemnasium.com/gwdg/rOCCI-server)

If you want to use rOCCI-server in a production environment, follow the production instructions for installation and
configuration, otherwise follow the developer instructions for installation and configuration.

Requirements
------------

The following setup is required
* Ruby >= 1.9.2
* Bundler gem installed (use ```gem install bundler```)
* OpenNebula >= 3.4 if the OpenNebula backend is used

The following setup is recommended
* usage of the Ruby Version Manger (RVM)
* Ruby >= 1.9.3

Installation
------------

### Production

Download the latest version from https://github.com/gwdg/rOCCI-server/tags

Extract downloaded file, remove it and change to rOCCI-server directory

    unzip gwdg-rOCCI-server-*.zip
    rm gwdg-rOCCI-server-*.zip
    cd gwdg-rOCCI-server-*

or clone this GIT repository and switch to a numbered branch, e.g. stable `0.5.x`

    git clone git://github.com/gwdg/rOCCI-server.git
    cd rOCCI-server
    git checkout 0.5.x

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

To configure the behaviour of compute, network and storage resource creation, edit the backend specific extensions of
the OCCI model at `etc/backend/$BACKEND/model` (e.g. `etc/backend/dummy/model` for the dummy backend).

To change the predefined resource or OS templates, you can adapt the existing templates in `etc/backend/$BACKEND/templates`
or add new templates. If resource or OS templates are already registered in the backend, they will be automatically
discovered by rOCCI-server.

### OpenNebula backend

If you want to change the actual deployment within OpenNebula you can change the OpenNebula templates in the files in
`etc/backend/opennebula/one_templates`.

Templates registered within OpenNebula will be made available by rOCCI as OS templates. To properly use these templates
 ensure that the permissions are set correctly. If the templates are only used by the owner of the template, the
 permission must be `400` or `u--`for the user. If the templates should be used by users from the same group, the
 permissions must at least be `440` or `uu-` for both user and group.

To configure resource templates (e.g. small, medium, large, ...) change the files in `etc/backend/opennebula/templates`.

For the OpenNebula backend a special server user is required in OpenNebula. To create a user named occi run the
following command in your OpenNebula environment (replace $RANDOM with a secure password!):

    oneuser create occi $RANDOM --driver server_cipher

Make sure that the user is member of the oneadmin group

    oneuser chgrp occi oneadmin

After copying `etc/backend/opennebula/opennebula.json` to `etc/backend/default.json` you have to adapt the admin and
password attributes in that file to the ones you chose during the user creation.

If you want to use basic or digest authentication for users of rOCCI-server you have to create the users in OpenNebula
 with the `core` auth driver. For a user named `john` the command may look like this

    oneuser create john johnspassword --driver core

If you want to use X.509 authentication for your users, you need to create the users in OpenNebula with the X.509
driver. For a user named `doe` the command may look like this

    oneuser create doe "/C=US/O=Doe Foundation/CN=John Doe" --driver x509

For more information have a look at the
[OpenNebula Documentation on x509 Authentication](http://opennebula.org/documentation:rel3.6:x509_auth)

Usage
-----

rOCCI-server is using passenger to be deployed into a webserver.

#### RVM

Detailed information on setting up and using RVM can be found on the [RVM website](http://rvm.io/).

**Warning:** Do **NOT** install RVM as root, you should always use a different user account with sudo privileges.
This is **NOT** just an annoying complication, RVM will **NOT** work properly when installed from the
root account! We will use `rocci` user account. 

Install RVM

    curl -L https://get.rvm.io | sudo bash -s stable

Add `rocci` user to `rvm` group - he will be responsible for installing new rubies.

    usermod -a -G rvm rocci

Log out and log back in (always as `rocci`) and make sure that RVM is working

    rvm info

Check RVM requirements and install missing packages

    rvm requirements

Setup RVM for rOCCI-server (change the ruby version to your favorite one)

    cd rOCCI-server
    rvm install ruby-1.9.3
    rvm --rvmrc --create ruby-1.9.3@rOCCI-server

Reload RVM configuration for this directory

    cd ..
    cd rOCCI-server

Install gems using bundler

    bundle install

Proceed with Passenger configuration

#### Passenger

rOCCI-server will work with the default passenger setup even though this setup is not recommended for production. To use
advanced features such as X.509 authentication, you need to set up passenger with a separate Nginx or Apache webserver.
Luckily, this is pretty easy. Detailed instructions can be found in the
[Passenger Documentation](http://www.modrails.com/documentation.html).

To use the standalone passenger with nginx run the following command (and maybe follow the installation steps) and
rOCCI-server is running

    bundle exec passenger start

To install rOCCI-server with RVM and either Nginx or Apache follow the steps below.

#### Nginx

**Warning:** If you are running SL6, `rvmsudo` won't work properly until you add paths from `rvm info | grep PATH` to
`Defaults    secure_path = ...` using `visudo`.

**Note:** If you intend to use several CAs for client certificate validation, you should use Apache as Nginx currently only
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

**Note:** There is no need to run this command with `rvmsudo`, Apache2 module will be compiled locally
and the script will provide you with additional LoadModule lines that you have to manually add to Apache's
configuration files.

Let passenger guide you through installing and configuring Apache2

    bundle exec passenger-install-apache2-module

Create a new VirtualHost in the sites-available directory of Apache (e.g. in `/etc/apache2/sites-available/occi-ssl`)
with the following content (adapt to your settings, especially $USER, ServerName and SSLCertificate[Key]File):

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
