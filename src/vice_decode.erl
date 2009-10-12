% BinaryVice - Improved Erlang Serialization
% Copyright (c) 2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (vice_decode).
-export ([from_binary/2]).

from_binary(Schema, Binary) -> 
    % If it's a placeholder, then encode it.
    % Otherwise, continue walking the structure.
    case vice_utils:is_placeholder(Schema) of
        true -> decode(Schema, Binary);
        false -> 
            
            walk(Schema, Binary)
    end.
    
walk(Schema, Binary) when is_list(Schema) -> 
    Length = length(Schema),
    F = fun(_X, {Values, AccBinary, [S|AccSchema]}) ->
        {Value, AccBinary1} = from_binary(S, AccBinary),
        {[Value|Values], AccBinary1, AccSchema}
    end,
    {Values1, Binary1, _} = lists:foldl(F, {[], Binary, Schema}, lists:seq(1, Length)),
    {lists:reverse(Values1), Binary1};
    
walk(Schema, Binary) when is_tuple(Schema) ->
    {Values, Rest} = walk(tuple_to_list(Schema), Binary),
    {list_to_tuple(Values), Rest};
        
%%% Didn't match anything, so ignore.
walk(Schema, Binary) -> 
    {Schema, Binary}.
    
    
%%% - DECODING - %%%

decode(atom@, B) ->
    <<Size:16/integer, AtomName:Size/binary, Rest/binary>> = B,
    {list_to_atom(binary_to_list(AtomName)), Rest};
    
decode(boolean@, <<B, Rest/binary>>) ->
    {B == 1, Rest};

decode(binary@, B) -> decode({binary@, 4}, B);
decode({binary@, Size}, B) ->
    BitSize = Size * 8,
    <<Length:BitSize/integer, Binary:Length/binary, Rest/binary>> = B,
    {Binary, Rest};

decode(bitstring@, B) -> decode({bitstring@, 4}, B);
decode({bitstring@, Size}, B) ->
    BitSize = Size * 8,
    <<Length:BitSize/integer, Rest/binary>> = B,
    Padding = 8 - (Length rem 8),
    <<BitString:Length/bits, 0:Padding, Rest1/binary>> = Rest,
    {BitString, Rest1};

decode(integer@, B) -> decode({integer@, 4}, B);
decode({integer@, Size}, B) -> 
    BitSize = Size * 8 - 1, 
    <<IsNeg:1/integer, Value:BitSize/integer, Rest/binary>> = B,
    Value1 = case IsNeg == 1 of
        true  -> bnot Value;
        false -> Value
    end,
    {Value1, Rest};
    
decode(string@, B) -> decode({string@, 4}, B);
decode({string@, Size}, B) -> 
    {Binary, Rest} = decode({binary@, Size}, B),
    {binary_to_list(Binary), Rest};

decode({list@, Schema}, B) ->
    <<Length:32/integer, B1/binary>> = B,
    F = fun(_, {Values, AccB}) ->
        {Value, AccB1} = from_binary(Schema, AccB),
        {[Value|Values], AccB1}
    end,
    {Values, Rest} = lists:foldl(F, {[], B1}, lists:seq(1, Length)),
    {lists:reverse(Values), Rest};

decode({tuple@, Schema}, B) ->
    {Values, Rest} = decode({list@, Schema}, B),
    {list_to_tuple(Values), Rest};

decode(dict@, B) ->
    {List, Rest} = decode(list@, B),
    {dict:from_list(List), Rest};
    
decode({dict@, KeySchema, ValueSchema}, B) -> 
    <<Length:32/integer, B1/binary>> = B,
    F = fun(_, {AccDict, AccB}) ->
        {Key, AccB1} = from_binary(KeySchema, AccB),
        {Value, AccB2} = from_binary(ValueSchema, AccB1),
        {dict:store(Key, Value, AccDict), AccB2} 
    end,
    {_Dict, _Rest} = lists:foldl(F, {dict:new(), B1}, lists:seq(1, Length));


decode(_Schema, B) -> 
    <<Size:16/integer, B1:Size/binary, Rest/binary>> = B,
    {
        binary_to_term(<<131, B1/binary>>),
        Rest
    }.