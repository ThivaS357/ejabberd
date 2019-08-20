-module(mod_chapz_fcm).
-author("Sabapathippilai Thipakar").

-behaviour(gen_mod).

-include("ejabberd.hrl").
-include("xmpp.hrl").
-include("logger.hrl").

-include("mod_muc_room.hrl").
-include("ejabberd_commands.hrl").
-include("mod_mam.hrl").


-export([start/2, stop/1, depends/2,mod_opt_type/1,send_message/1, send_group_message/3]).


start(_Host, _Opt) ->
    ejabberd_hooks:add(offline_message_hook, _Host, ?MODULE, send_message, 100),
    ejabberd_hooks:add(muc_filter_message, _Host, ?MODULE,send_group_message, 100).  
stop (_Host) ->
    ejabberd_hooks:delete(offline_message_hook, _Host, ?MODULE, send_message, 100),
    ejabberd_hooks:add(muc_filter_message, _Host, ?MODULE,send_group_message, 100).

depends(_Host, _Opts) ->
  [].

mod_opt_type(_) ->
  [].

send_message({_Action, #message{from = From, to = To, body = Body, id=Id, type=Type, lang=Lang}}) -> 
    FromAddress = string:concat(string:concat(binary_to_list(From#jid.luser),"@"),binary_to_list(From#jid.lserver)),
    ToAddress = string:concat(string:concat(binary_to_list(To#jid.luser),"@"),binary_to_list(To#jid.lserver)),
    MessageId = binary_to_list(Id),
    MessageLang = binary_to_list(Lang),
    [FirstMessage|_] = Body,
    Message=binary_to_list(FirstMessage#text.data),
    ?INFO_MSG("~nFrom: ~n~p~nTo: ~p~nId: ~p~nType: ~p~nLang: ~p~nMessage: ~p~n", [FromAddress, ToAddress, MessageId, Type,MessageLang, Message]),
    RequestMothed = post,
    RequestURL = "http://localhost:7100/chapz/offline/message",
    ?INFO_MSG("Request URL: ~p~n",[RequestURL]),
    RequestHeader = [],
    RequestType = "application/json",
    RequestBody = "{\"fromAddress\":\"" ++ FromAddress ++ "\",\"toAddress\":\"" ++ ToAddress ++ "\",\"messageId\":\"" ++ MessageId ++ "\",\"messageType\":\"" ++ atom_to_list(Type) ++ "\",\"messageLanguage\":\"" ++ MessageLang ++ "\",\"message\":" ++ Message++ "}",
    RequestHTTPOptions = [],
    RequestOptions = [],
    ?INFO_MSG("Body:~p~n",[RequestBody]),
    case httpc:request( RequestMothed,{ RequestURL, RequestHeader, RequestType, RequestBody }, RequestHTTPOptions, RequestOptions ) of
	{ok, {{_, Code, _}, ResponseHead, ResponseBody}} when Code >= 200, Code =< 299 ->
	    ?INFO_MSG("Code ~p~nHeader ~p~nBody ~p~n",[Code,ResponseHead,ResponseBody]);
	Error ->
	    ?INFO_MSG("Error ~p~n",[Error])
    end.

-spec send_group_message(message(), mod_muc_room:state(), binary()) -> message().
send_group_message(#message{from = From, to = To, body = Body, id=Id, type=Type, lang=Lang} =Pkt,
		   #state{jid = RoomJID},
		   FromNick) ->
               FromAddress = string:concat(string:concat(binary_to_list(From#jid.luser),"@"),binary_to_list(From#jid.lserver)),
               ToAddress = string:concat(string:concat(binary_to_list(To#jid.luser),"@"),binary_to_list(To#jid.lserver)),
               MessageId = binary_to_list(Id),
               MessageLang = binary_to_list(Lang),
               [FirstMessage|_] = Body,
               Message=binary_to_list(FirstMessage#text.data),
               MessageType=atom_to_list(Type),
               MessageRoomJID=string:concat(string:concat(binary_to_list(RoomJID#jid.luser),"@"),binary_to_list(RoomJID#jid.lserver)),
               MessageSenderNickName=binary_to_list(FromNick),
               ?INFO_MSG("~nFrom: ~p,~nTo: ~p,~nMessageID: ~p,~nLang: ~p,~nMessage: ~p,~nMessageType: ~p,~nRoomJID: ~p,~nNickName: ~p~n",
               [FromAddress, ToAddress, MessageId, MessageLang, Message, MessageType, MessageRoomJID, MessageSenderNickName]), 
               RequestMothed = post,
               RequestURL = "http://localhost:7100/chapz/group/message",
               ?INFO_MSG("Request URL: ~p~n",[RequestURL]),
               RequestHeader = [],
               RequestType = "application/json",
               RequestBody = "{\"fromAddress\":\"" ++ FromAddress ++ "\",\"toAddress\":\"" ++ ToAddress ++ "\",\"messageId\":\"" ++ MessageId ++ "\",\"messageType\":\"" ++ atom_to_list(Type) ++ "\",\"messageLanguage\":\"" ++ MessageLang ++ "\",\"message\":" ++ Message++ ",\"roomId\":\"" ++ MessageRoomJID ++ "\",\"nickName\":\"" ++ MessageSenderNickName ++ "\"}",
               RequestHTTPOptions = [],
               RequestOptions = [],
               ?INFO_MSG("Body:~p~n",[RequestBody]),
               case httpc:request( RequestMothed,{ RequestURL, RequestHeader, RequestType, RequestBody }, RequestHTTPOptions, RequestOptions ) of
	                {ok, {{_, Code, _}, ResponseHead, ResponseBody}} when Code >= 200, Code =< 299 ->
	                    ?INFO_MSG("Code ~p~nHeader ~p~nBody ~p~n",[Code,ResponseHead,ResponseBody]);
	                Error ->
	                    ?INFO_MSG("Error ~p~n",[Error])
               end, Pkt.

