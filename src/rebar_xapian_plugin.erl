-module(rebar_xapian_plugin).

-define(DEBUG(Msg, Args), ?LOG(debug, Msg, Args)).
-define(WARN(Msg, Args), ?LOG(warn, Msg, Args)).
-define(LOG(Lvl, Msg, Args), rebar_log:log(Lvl, Msg, Args)).
-define(ABORT(Msg, Args), rebar_utils:abort(Msg, Args)).

%% standard rebar hooks
-export([preprocess/2]).


%%
%% Plugin API
%%


preprocess(_Config, _AppFile) ->
    Cwd = rebar_utils:get_cwd(),
    %% Cwd is "/home/user/erlang/xapian/deps/proper" or 
    %%        "/home/user/erlang/xapian".
    CwdList = filename:split(Cwd),
    case lists:last(CwdList) of
        "xapian" ->
            set_vars();
        _OtherApp ->
            ok
    end,
    {ok, []}.



%%
%% Internal Functions
%%

set_vars() ->

    case os:getenv("XAPIAN_REBAR") of
    false ->
        ?DEBUG("Set env vars xapian\n", []),
		os:putenv("XAPIAN_REBAR", "true"),

        export_env("XAPIAN_CXXFLAGS", " xapian-config --cxxflags"),
        export_env("XAPIAN_LDFLAGS", " xapian-config --libs"),


        case os:getenv("XAPIAN_REBAR_COVER") of
        "true" ->
            ?DEBUG("Enable coverage for xapian\n", []),
            append_env(" --coverage ", "XAPIAN_CXXFLAGS", ""),
            append_env(" -lgcov ", "XAPIAN_LDFLAGS", "");
        _ ->
            ?DEBUG("Disable coverage for xapian\n", []),
            ok
        end;
    
    _ -> 
        ?DEBUG("Env vars for xapian already seted.\n", [])
    end,
        
    ok.


export_env(Name, Cmd) ->
    FormatFn = fun(X) -> X end,
    export_env(Name, Cmd, FormatFn).
    

export_env(Name, Cmd, FormatFn) ->
	case os:getenv(Name) of
	false ->
		{0, Value} = eunit_lib:command(Cmd),
		os:putenv(Name, FormatFn(remove_new_string(Value))),
		ok;
	_ -> ok
	end.

append_env(Prefix, Name, Suffix) ->
	case os:getenv(Name) of
	Value when (Value =/= false) -> 
		os:putenv(Name, Prefix ++ Value ++ Suffix),
        true
	end.

remove_new_string(Str) ->
    [C||C <- Str, C =/= $\n].
