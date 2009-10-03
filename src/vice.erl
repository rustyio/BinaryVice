-module (vice).
-export ([to_binary/2, to_term/2]).

% TODO -
% - Handle lists. The placeholder should be {'$list$', Schema}
% - Handle dictionaries. Convert to lists and back. Placeholder should be {'$dict$', Schema}

% Schema is a term of the same structure as Term,
% except that fields can be replaced by '$'. When they 
% are, then that field is seen as a "data" field, and 
% is serialized.
% How are lists and dicts handled?
to_binary(Schema, Term) -> 
    Response = walk(Schema, Term),
    <<Response/binary>>.
        
to_term(_Schema, _Binary) -> ok.

%%% - TERM TO BINARY - %%%
walk(Schema, Term) ->
    % If it's a placeholder, then encode it.
    % Otherwise, continue walking the structure.
    case is_placeholder(Schema, Term) of
        true -> encode(type(Schema), Term);
        false -> 
            case type(Schema) == type(Term) of 
                true -> walk(type(Schema), Schema, Term);
                false -> throw({mismatched_types, Schema, Term})
            end
    end.
    
walk(list, _Schema, _Term) -> 
    throw(not_yet_supported);
    
walk(tuple, Schema, Term) ->
    case {tuple_size(Schema), tuple_size(Term)} of
        {0, 0} -> <<>>;
        {N, N} -> 
            F = fun(X, AccIn) ->
                B = walk(element(X, Schema), element(X, Term)),
                <<AccIn/binary, B/binary>>
            end,
            lists:foldl(F, <<>>, lists:seq(1, N));
        _ -> throw({mismatch_tuples, Schema, Term})
    end;
    
    
%%% Didn't match anything, so ignore.
walk(_, _, _) -> 
    <<>>.
    
encode(_, Term) -> 
    <<_:2/binary, Rest/binary>> = term_to_binary(Term),
    Rest.

%%% - BINARY TO TERM - %%%


% is_placeholder(Schema, Term) - Return true if the provided Schema
% is a placeholder, meaning that we should encode the term. 
% Throw an exception if the Term does not match the expected type.
% Otherwise, return false.
is_placeholder('$atom$', O) when is_atom(O) -> true;
is_placeholder('$atom$', O) -> throw({not_an_atom, O});
is_placeholder('$binary$', O) when is_binary(O) -> true;
is_placeholder('$binary$', O) -> throw({not_a_binary, O});
is_placeholder('$boolean$', O) when is_boolean(O) -> true;
is_placeholder('$boolean$', O) -> throw({not_a_boolean, O});
is_placeholder('$float$', O) when is_float(O) -> true;
is_placeholder('$float$', O) -> throw({not_a_float, O});
is_placeholder('$function$', O) when is_function(O) -> true;
is_placeholder('$function$', O) -> throw({not_a_function, O});
is_placeholder('$integer$', O) when is_integer(O) -> true;
is_placeholder('$integer$', O) -> throw({not_a_integer, O});
is_placeholder('$pid$', O) when is_pid(O) -> true;
is_placeholder('$pid$', O) -> throw({not_a_pid, O});
is_placeholder('$reference$', O) when is_reference(O) -> true;
is_placeholder('$reference$', O) -> throw({not_a_reference, O});
is_placeholder('$string$', O) when is_list(O) -> true;
is_placeholder('$string$', O) -> throw({not_a_string, O});
is_placeholder('$tuple$', O) when is_tuple(O) -> true;
is_placeholder('$tuple$', O) -> throw({not_a_tuple, O});
is_placeholder('$list$', O) when is_list(O) -> true;
is_placeholder('$list$', O) -> throw({not_a_list, O});
is_placeholder(_, _) -> false.

% Return an atom that signifies the type of O.
type(O) when is_atom(O) -> atom;
type(O) when is_binary(O) -> binary;
type(O) when is_boolean(O) -> boolean;
type(O) when is_float(O) -> float;
type(O) when is_function(O) -> function;
type(O) when is_integer(O) -> integer;
type(O) when is_list(O) -> list;
type(O) when is_pid(O) -> pid;
type(O) when is_reference(O) -> reference;
type(O) when is_tuple(O) -> tuple;
type(O) -> throw({unexpected_type, O}).