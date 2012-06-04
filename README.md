rOCCI Server - A Ruby OCCI Server
=============================

[![Build Status](https://secure.travis-ci.org/gwdg/rOCCI-server.png)](http://travis-ci.org/gwdg/rOCCI-server)

Requirements
------------

The following setup is recommended

* usage of the Ruby Version Manger
* Ruby 1.9.3
* Bundler gem installed (use ```gem install bundler```)

Installation
------------

### Stable version

Download the latest version from http://dev.opennebula.org/projects/ogf-occi/files

Extract file

    tar xzf rOCCI-*.tar.bz
    unzip rOCCI-*.zip

Install dependencies

    bundle install --deployment

### Latest version

Checkout latest version from GIT:

    git clone git://github.com/gwdg/rOCCI-server.git

Change to rOCCI folder

    cd rOCCI-server

Install dependencies for deployment

    bundle install --deployment

Configure
---------

Edit etc/occi-server.conf and adapt to your setting.

To configure the behaviour of compute, network and storage resource creation, edit the OpenNebula specific extensions of the OCCI model at etc/backend/opennebula/model . If you want to change the actual deployment templates, change the files in etc/backend/opennebula/one_templates .

To configure OpenNebula resource templates (e.g. small, medium, large, ...) change the files in etc/backend/opennebula/templates .

Usage
-----

Run Passenger

    passenger start

Testing
-------

Use curl to request all categories

    curl -X GET http://localhost:3000/-/

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
5. Create an Issue with a link to your branch