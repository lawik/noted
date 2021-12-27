#!/bin/bash

set -e

export MIX_ENV=prod

npm install --prefix ./assets
mix deps.get --only prod
mix deps.compile

mix assets.deploy

mix release --overwrite
