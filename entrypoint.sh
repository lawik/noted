#!/bin/sh
set -x 

bin/noted eval "Noted.Release.migrate"
bin/noted start
