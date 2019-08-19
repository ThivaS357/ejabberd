-module(mod_chapz_fcm).

-author("Sabapathippilai Thipakar").

-include("ejabberd.hrl").
-include("xmpp.hrl").
-include("logger.hrl").


-export([start/2, stop/1, send_message/1]).


start(_Host, _Opt) ->
    ejabberd_hooks:add(offline_message_hook, _Host, ?MODULE, send_message, 100).   
stop (_Host) ->
    ejabberd_hooks:delete(offline_message_hook, _Host, ?MODULE, send_message, 100).

send_message({_Action, #message{from = From, to = To, body = Body, id=Id, type=Type, lang=Lang}}) -> 
    FromAddress = string:concat(string:concat(binary_to_list(From#jid.luser),"@"),binary_to_list(To#jid.lserver)),
    ToAddress = string:concat(string:concat(binary_to_list(To#jid.luser),"@"),binary_to_list(From#jid.lserver)),
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
    RequestBody = "{\"fromAddress\":\"" ++ FromAddress ++ "\",\"toAddress\":\"" ++ ToAddress ++ "\",\"messageId\":\"" ++ MessageId ++ "\",\"messageType\":\"" ++ atom_to_list(Type) ++ "\",\"messageLanguage\":\"" ++ MessageLang ++ "\",\"message\":\"" ++ Message++ "\"}",
    RequestHTTPOptions = [],
    RequestOptions = [],
    ?INFO_MSG("Body:~p~n",[RequestBody]),
    case httpc:request( RequestMothed,{ RequestURL, RequestHeader, RequestType, RequestBody }, RequestHTTPOptions, RequestOptions ) of
	{ok, {{_, Code, _}, ResponseHead, ResponseBody}} when Code >= 200, Code =< 299 ->
	    ?INFO_MSG("Code ~p~nHeader ~p~nBody ~p~n",[Code,ResponseHead,ResponseBody]);
	Error ->
	    ?INFO_MSG("Error ~p~n",[Error])
    end.

