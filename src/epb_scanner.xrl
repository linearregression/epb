Definitions.

EOL = [\r\n]
WS = [\s\n\t\r\v\f]
WS_NONL = [\s\t\r\v\f]
UNPRINTABLE = [\x00-\x19]
DIGIT = [0-9]
OCTAL_DIGIT = [0-7]
HEX_DIGIT = [0-9a-fA-F]
LETTER = [a-zA-Z_]
ALNUM = [a-zA-Z0-9_]
ESCAPE = [abfnrtv\\\?\'\"]
SYMBOL = ([=;{}\[\]()./-]|\+)
SIGN = (-|\+)
FLOAT = [fF]

Rules.

{UNPRINTABLE}+                                          : skip_token.  %% remove unprintables
{WS}+                                                   : skip_token.  %% remove whitespace
#.*{EOL}+                                               : skip_token.  %% sh-style comments
//.*{EOL}+                                              : skip_token.  %% C style single-line comments
/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/               : skip_token.  %% C-style block comments
{LETTER}{ALNUM}*                                        : {token, select_id_type(TokenChars, TokenLine)}.
\"([^\"]|\\\")*\"                                       : {token, {string, TokenLine, unquote(TokenChars)}}.
{SIGN}?{DIGIT}+([eE]{SIGN}?{DIGIT}+)?{FLOAT}            : {token, {float, TokenLine, parse_float(TokenChars)}}.
{SIGN}?{DIGIT}+\.{DIGIT}+([eE]{SIGN}?{DIGIT}+)?{FLOAT}? : {token, {float, TokenLine, parse_float(TokenChars)}}.
0x{HEX_DIGIT}+                                          : {token, {integer, TokenLine, hex_to_int(TokenChars)}}.
0{OCTAL_DIGIT}+                                         : {token, {integer, TokenLine, oct_to_int(TokenChars)}}.
(0|{SIGN}?[1-9]{DIGIT}*)                                : {token, {integer, TokenLine, list_to_integer(TokenChars)}}.
{SYMBOL}                                                : {token, {list_to_atom(TokenChars), TokenLine}}.

Erlang code.

%% Top level construct definitions.
-define(DEFINE, ["message", "enum", "service", "extend"]).

%% Declarations made within definitions or at top-level.
-define(DECLARE, ["option", "import", "package"]).

%% Field types
-define(TYPE, ["double", "float", "int32", "int64", "uint32",
               "uint64", "sint32", "sint64", "fixed32",
               "fixed64", "sfixed32", "sfixed64", "bool",
               "string", "bytes"]).

%% Field rules
-define(RULE, ["required", "optional", "repeated"]).

%% Other keywords
-define(KEYWORD, ["public", "extensions", "to", "max", "rpc", "returns"]).

%% Flip through the reserved words and create tokens of the proper type.
select_id_type(T, Line) ->
    select_id_type(T, Line, [{definition, ?DEFINE},
                             {declararation, ?DECLARE},
                             {type, ?TYPE},
                             {rule, ?RULE},
                             {keyword, ?KEYWORD}]).

%% When none of the keywords match, it's a regular identifier
select_id_type(T, Line, []) ->
    {identifier, Line, T};
%% special-casing other keywords so they come out as terminals
select_id_type(T, Line, [{keyword, K}|Rest]) ->  
    case lists:member(T, K) of
        true ->
            {list_to_atom(T), Line};
        false ->
            select_id_type(T, Line, Rest)
    end;
select_id_type(T, Line, [{NT, Toks}|Rest]) -> 
    case lists:member(T, Toks) of
        true ->
            {NT, Line, T};
        false ->
            select_id_type(T, Line, Rest)
    end.

unquote(Str) ->
    %% Quote is at beginning and end of the string, strip them off.
    Stripped = lists:sublist(Str, 2, length(Str)-2),
    unescape(Stripped, []).

unescape([], Acc) ->
    lists:reverse(Acc);
unescape([$\\, C|Rest], Acc) ->
    unescape(Rest, [C|Acc]);
unescape([C|Rest], Acc) ->
    unescape(Rest, [C|Acc]).

hex_to_int("0x"++Hex) ->
    list_to_integer(Hex, 16).

oct_to_int("0"++Oct) ->
    list_to_integer(Oct, 8).

parse_float(Float0) ->
    Float = case lists:last(Float0) of
                F when F == $f orelse F == $F -> lists:sublist(Float0, 0, length(Float0) - 1);
                _ -> Float0
            end,
    list_to_float(Float).
