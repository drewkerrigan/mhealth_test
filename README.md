mhealth_test
============

A bash based driver for simple mhealth benchmarking tests.

## Prerequisites

sudo npm install riak-js@latest

## Usage

./mhealth_test.sh -c (config file) -t (time) -w (workers) [-d]

example usage : ./mhealth_test.sh -c mhealth_test.cfg -t 60 -w 1
                
## Options

* -c (config: location of config file)
* -t (time: (in seconds) 30 | 60 | 120)
* -w (workers: 1 | 10 | 20 | 100)
* -d (debug, only prints diagnostic information about what will be run)

## Test Deployment Steps

Check out the project and set it up
* cd
* git clone git://github.com/drewkerrigan/mhealth_test.git
* cd mhealth_test
* npm install riak-js@latest

Set up performancetest.rake in the mHealth portal application
* cd /usr/local/src/mhealth
* cp ~/mhealth_test/utilities/performancetest.rake performancetest.rake
* cp ~/mhealth_test/utilities/performancetest.yml performancetest.yml

Clean the DB and prepopulate it with 1000 users and 5 measures each
* bundle exec rake --rakefile performancetest.rake db:unpop
* bundle exec rake --rakefile performancetest.rake db:prepop["users.txt",1000,5]

Move the users.txt, configure and run the test
* cd ~/mhealth_test/
* cp /usr/local/src/mhealth/users.txt users.txt
* cp config/mhealth_test.cfg.example config/mhealth_test.cfg
* vi config/mhealth_test.cfg #verify namespace, riakhost, apihost, riakbase, and riakport settings
* ./mhealth_test.sh -c config/mhealth_test.cfg -t 600 -w 1

Check stats.txt in the results/ directory