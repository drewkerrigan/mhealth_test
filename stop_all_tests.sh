#!/bin/bash
kill -9 `ps -ef | grep mhealth_test | grep -v grep | awk '{print $2}'`