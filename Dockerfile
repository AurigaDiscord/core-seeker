FROM elixir:1.6.0-alpine

WORKDIR /app

RUN mix local.hex --force \
    && mix local.rebar --force \
    && /root/.mix/rebar3 update

ADD mix.exs /app/mix.exs
RUN mix deps.get \
    && mix deps.compile

ADD config /app/config
ADD lib /app/lib
RUN mix compile

CMD ["mix", "run", "--no-halt"]
