%%%-------------------------------------------------------------------
%% @doc bravodelta public API
%% @end
%%%-------------------------------------------------------------------

-module(bravodelta_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  lager:start(),
  hackney:start(),
  bravodelta_sup:start_link().


stop(_State) -> ok.

%% internal functions

test(FileName) -> bdd:test(FileName).
