-module (vice_decode).
-export ([from_binary/2]).

from_binary(Schema, Binary) -> 
    SchemaType = vice_utils:type(Schema),
    % If it's a placeholder, then encode it.
    % Otherwise, continue walking the structure.
    case vice_utils:is_placeholder(Schema) of
        true -> decode(Schema, Binary);
        false -> walk(SchemaType, Schema, Binary)
    end.
    
walk(list, Schema, Binary) -> 
    Length = length(Schema),
    F = fun(X, {Values, AccBinary}) ->
        {Value, AccBinary1} = from_binary(lists:nth(X, Schema), AccBinary),
        {[Value|Values], AccBinary1}
    end,
    {Values1, Binary1} = lists:foldl(F, {[], Binary}, lists:seq(1, Length)),
    {lists:reverse(Values1), Binary1};
    
walk(tuple, Schema, Binary) ->
    % Decode each item according to its schema, and replace
    % it in the Schema itself.
    Length = size(Schema),
    F = fun(X, {AccSchema, AccBinary}) ->
        {Value, AccBinary1} = from_binary(element(X, AccSchema), AccBinary),
        {setelement(X, AccSchema, Value), AccBinary1}
    end,
    {_, _} = lists:foldl(F, {Schema, Binary}, lists:seq(1, Length));
    
%%% Didn't match anything, so ignore.
walk(_, Schema, Binary) -> 
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
    <<Size:24/integer, B1:Size/binary, Rest/binary>> = B,
    {
        binary_to_term(<<131, B1/binary>>),
        Rest
    }.