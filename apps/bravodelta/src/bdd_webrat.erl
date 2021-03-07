-module(bdd_webrat).

-export([step/3]).

step(_Config, _Global, {step_given, _N, ["I am on the home page"]}) ->
  bdd_utils:http_get(_Config, []);

step(_Config, _Global, {step_given, _N, ["I went to the", Page, "page"]}) ->
  bdd_utils:http_get(_Config, Page);

step(_Config, _Given, {step_when, _N, ["I go to the home page"]}) ->
  %io:format("DEBUG go home.~n"),
  bdd_utils:http_get(_Config, []);

step(_Config, _Given, {step_when, _N, ["I go to the", Page, "page"]}) ->
  %io:format("DEBUG go to the ~p page~n", [Page]),
  bdd_utils:http_get(_Config, Page);

step(_Config, _Given, {step_when, _N, ["I try to go to the", Page, "page"]}) ->
  %io:format("DEBUG expect FAIL when going to the ~p page~n", [Page]),
  bdd_utils:http_get(_Config, Page, not_found);

step(_Config, _Given, {step_when, _N, ["I click on the", Link, "link"]}) ->
  [URL | _] = [bdd_utils:html_find_link(Link, HTML) || HTML <- (_Given), HTML =/= []],
  %io:format("DEBUG URL ~p FROM ~p~n",[URL, _Given]),
  Result =
    case URL of
      [] ->
        io:format("CANNOT FIND LINK ~s~n", [Link]),
        error;

      _ -> bdd_utils:http_get(_Config, URL, ok)
    end,
  %io:format("DEBUG: when I click result ~p~n", [Result]),
  Result;

step(_Config, _Result, {step_then, _N, ["I should not see", Text]}) ->
  %io:format("DEBUG step_then result ~p should NOT have ~p on the page~n", [_Result, Text]),
  bdd_utils:html_search(Text, _Result, false);

step(_Config, _Result, {step_then, _N, ["I should see", Text]}) ->
  %io:format("DEBUG step_then result ~p should have ~p on the page~n", [_Result, Text]),
  bdd_utils:html_search(Text, _Result);

step(Config, _Given, {step_when, _N, ["I make a GET request to", Url]}) ->
  %io:format("DEBUG step_when I make a GET request to ~p ~n~p ~n", [Url,_Given]),
  {url, ServerUrl} = lists:keyfind(url, 1, Config),
  hackney:request(
    get,
    ServerUrl ++ list_to_binary(Url),
    [],
    <<>>,
    [{pool, default}, {with_body, true}]
  );

step(Config, _Given, {step_given, _N, ["I login as", UserName, "with password", Password]}) ->
  LoginUrl = bdd_utils:config(Config, url) ++ "/accounts/login/",
  {ok, _, Headers, _} = hackney:request(get, LoginUrl, [], <<>>, [{pool, default}]),
  {_, CSRFToken} = lists:keyfind(<<"X-CSRFToken">>, 1, Headers),
  {_, SessionId} = lists:keyfind(<<"X-SessionID">>, 1, Headers),
  hackney:request(
    post,
    LoginUrl,
    [
      {<<"content-type">>, <<"application/x-www-form-urlencoded">>},
      {<<"X-CSRFToken">>, CSRFToken},
      {<<"X-SessionID">>, SessionId},
      {<<"Referer">>, list_to_binary(LoginUrl)},
      {<<"X-Requested-with">>, <<"XMLHttpRequest">>}
    ],
    {form, [{<<"login">>, list_to_binary(UserName)}, {<<"password">>, list_to_binary(Password)}]},
    [
      {
        cookie,
        [
          {<<"csrf_token">>, CSRFToken, [{path, <<"/">>}]},
          {<<"csrftoken">>, CSRFToken, [{path, <<"/">>}]}
        ]
      },
      {with_body, true}
    ]
  );

step(_Config, Result, {step_then, _N, ["the response status must be", Status]}) ->
  Status0 = list_to_integer(Status),
  [{_, Status0, _, _} | _] = Result;

step(_Config, Result, {step_then, _N, ["the json at path", Path, "must be", Json]}) ->
  [{ok, _StatusCode, _Headers, Body} | _] = Result,
  Json0 = list_to_binary(Json),
  io:format("DEBUG step_then the json at path ~p must be ~p~n~p~n", [Path, Json0, Body]),
    io:format("DEBUG ~p~n", [ejsonpath:q(Path, jsx:decode(Body, [return_maps]))]),
    debugger:start(),
  {[Json0 | _], _} = ejsonpath:q(Path, jsx:decode(Body, [return_maps])),
  %io:format("DEBUG step_then result ~p should NOT have ~p on the page~n", [Body, Json0]),
  true.
