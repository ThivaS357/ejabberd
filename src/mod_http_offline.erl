-module(mod_http_offline).

-author("Sabapathippilai Thipakar").

-behaviour(gen_mod).

-export([start/2, stop/1, create_message/3]).

-include("ejabberd.hrl").
-include("jlib.hrl").
-include("logger.hrl").

start(_Host, _Opt) -> 
    post_offline_message("testFrom", "testTo", "testBody"),
    ejabberd_hooks:add(offline_message_hook, _Host, ?MODULE, create_message, 50).   
stop (_Host) ->
    ejabberd_hooks:delete(offline_message_hook, _Host, ?MODULE, create_message, 50).
create_message(_From, _To, Packet) ->
    Type = xml:get_tag_attr_s("type", Packet),
    FromS = xml:get_tag_attr_s("from", Packet),
    ToS = xml:get_tag_attr_s("to", Packet),
    Body = xml:get_path_s(Packet, [{elem, "body"}, cdata]),
    if (Type == "chat") ->
      post_offline_message(FromS, ToS, Body)
    end.
post_offline_message(From, To, Body) ->
    ?INFO_MSG("Posting From ~p To ~p Body ~p~n",[From, To, Body]),
    ?INFO_MSG("post request sent (not really yet)", []).
