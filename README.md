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