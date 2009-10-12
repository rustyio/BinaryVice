% BinaryVice - Improved Erlang Serialization
% Copyright (c) 2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (vice_encode).
-export ([to_binary/2]).

%%% - TERM TO BINARY - %%%
to_binary(Schema, Term) ->
    % If it's a placeholder, then encode it.
    % Otherwise, continue walking the structure.
    case vice_utils:is_placeholder(Schema) of
        true -> 
            vice_utils:ensure_matching_types(Schema, Term),
            encode(Schema, Term);
        false -> walk(Schema, Term)
    end.
        
walk(Schema, Term) when is_list(Schema) -> 
    case {length(Schema), length(Term)} of
        {0, 0} -> <<>>;
        {N, N} ->
            F = fun(_, {AccB, [S|AccSchema], [T|AccTerm]}) ->
                B = to_binary(S, T),
                {<<AccB/binary, B/binary>>, AccSchema, AccTerm}
            end,
            {B, _, _} = lists:foldl(F, {<<>>, Schema, Term}, lists:seq(1, N)),
						
            B;
        _ -> throw({mismatched_lengths, Schema, Term})
    end;

walk(Schema, Term) when is_tuple(Schema) ->
    walk(tuple_to_list(Schema), tuple_to_list(Term));
    
%%% Didn't match anything, so ignore.
walk(_, _) -> 
    <<>>.


%%% - ENCODING - %%%

encode(atom@, O) ->
    B = list_to_binary(atom_to_list(O)),
    Size = size(B),
    <<Size:16/integer, B/binary>>;
    
encode(boolean@, O) -> 
    case O of
        true -> <<1>>;
        false -> <<0>>
    end;

encode(binary@, O) -> encode({binary@, 4}, O);
encode({binary@, Size}, O) ->
    Length = size(O),
    <<Length:(Size * 8)/integer, O/binary>>;
    
encode(bitstring@, O) -> encode({bitstring@, 4}, O);
encode({bitstring@, Size}, O) ->
    Length = bit_size(O),
    Padding = (8 - Length rem 8),
    <<Length:(Size * 8)/integer, O/bits, 0:Padding>>;    

encode(integer@, O) -> encode({integer@, 4}, O);
encode({integer@, Size}, O) -> 
    {FirstBit, O1} = case O < 0 of
        true  -> {1, bnot O};
        false -> {0, O}
    end,
    BitSize = Size * 8 - 1,
    B = <<FirstBit:1/integer, O1:BitSize/integer>>,
		B;
      
encode(string@, O) -> encode({string@, 4}, O);
encode({string@, Size}, O) -> encode({binary@, Size}, list_to_binary(O));
    
encode({list@, Schema}, O) -> 
    Length = length(O),
    F = fun(Item, Acc) ->
        B = to_binary(Schema, Item),
        <<Acc/binary, B/binary>>
    end,
    B = lists:foldl(F, <<>>, O),
    <<Length:32/integer, B/binary>>;

encode({tuple@, Schema}, O) ->
    encode({list@, Schema}, tuple_to_list(O)); 
 
encode(dict@, O) -> 
    encode(list@, dict:to_list(O));    

encode({dict@, KeySchema, ValueSchema}, O) -> 
    Length = dict:size(O),
    F = fun(Key, Value, Acc) ->
        KeyB = to_binary(KeySchema, Key),
        ValueB = to_binary(ValueSchema, Value),
        <<Acc/binary, KeyB/binary, ValueB/binary>>
    end,
    B = dict:fold(F, <<>>, O),
    <<Length:32/integer, B/binary>>;
        
encode(_Schema, O) -> 
    <<131,B/binary>> = term_to_binary(O),
    Size = size(B),
    <<Size:16/integer, B/binary>>.    
    