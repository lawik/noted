FROM hexpm/elixir:1.11.4-erlang-23.3.4.1-ubuntu-xenial-20210114 AS build
SHELL ["/bin/bash", "-c"]


# install build dependencies
RUN apt-get install -y npm git curl

RUN curl -fsSL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs
RUN npm install npm@latest -g && \
    npm install -g webpack

# prepare build dir
WORKDIR /app

# set build ENV
ENV MIX_ENV=prod
ENV NODE_ENV=production


# install mix dependencies
COPY mix.exs mix.lock ./
COPY config ./config

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/

COPY priv priv
COPY assets assets
RUN npm run deploy --prefix ./assets && \
    mix phx.digest priv/static


# compile and build release
COPY lib lib

RUN mix do compile, release


FROM hexpm/elixir:1.11.4-erlang-23.3.4.1-ubuntu-xenial-20210114 AS app

RUN apt install -y sqlite3


ENV LANG=C.UTF-8

WORKDIR /app

COPY --from=build  /app/_build/prod/rel/noted ./

ENV HOME=/app



COPY entrypoint.sh ./entrypoint.sh 
RUN chmod a+x entrypoint.sh 

ENTRYPOINT ["./entrypoint.sh"]

CMD ["run"]
