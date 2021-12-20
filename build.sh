#!/bin/bash

set -e

export MIX_ENV=prod

npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest

mix deps.get --only prod
mix deps.compile

mix release --overwrite
