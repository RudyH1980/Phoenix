# Build stage
FROM hexpm/elixir:1.18.3-erlang-27.3.4-debian-bookworm-20260316-slim AS builder

# Build tools
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app
ENV MIX_ENV="prod"

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/runtime.exs config/
COPY config/prod.exs config/

RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Build release
RUN mix compile
COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# Runner stage
FROM debian:bookworm-20260316-slim AS app

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/nl_NL.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG="nl_NL.UTF-8"
ENV LANGUAGE="nl_NL:nl"
ENV LC_ALL="nl_NL.UTF-8"

# IPv6 -- verplicht voor Fly.io Postgres
ENV ECTO_IPV6="true"
ENV ERL_AFLAGS="-proto_dist inet6_tcp"

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/phoenix_analytics ./

USER nobody

CMD ["/app/bin/server"]
