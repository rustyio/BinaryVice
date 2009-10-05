-module (vice).
-export ([to_binary/2, to_binary_version/3, from_binary/2, from_binary_version/2]).

% TODO -
% - Decoding of different versions.

% Schema is a term of the same structure as Term,
% except that fields can be replaced by '$'. When they 
% are, then that field is seen as a "data" field, and 
% is serialized.
% How are lists and dicts handled?
to_binary(Schema, Term) -> 
    Response = vice_encode:to_binary(Schema, Term),
    <<Response/binary>>.
    
to_binary_version(Version, Schema, Term) ->
    (Version >=0 andalso Version < 256) orelse throw({invalid_version_number, Version}),
    Response = vice_encode:to_binary(Schema, Term),
    <<Version:8/integer, Response/binary>>.
        
from_binary(Schema, Binary) -> 
    {Value, Rest} = vice_decode:from_binary(Schema, Binary),
    (Rest == <<>>) orelse throw({bytes_left_over, Binary}),
    Value.

from_binary_version(Versions, Binary) -> 
    <<Version:8/integer, Rest/binary>> = Binary,
    case Version of 
        131 -> {Version, binary_to_term(Binary)};
        _   -> 
            Schema = proplists:get_value(Version, Versions),
            {Version, from_binary(Schema, Rest)}
    end.