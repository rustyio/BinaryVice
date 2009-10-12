% BinaryVice - Improved Erlang Serialization
% Copyright (c) 2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (vice).
-export ([to_binary/2, to_binary_version/3, from_binary/2, from_binary_version/2]).

% Schema is a term of the same structure as Term,
% except that fields can be replaced by atom@ (or some other type). 
% This is then seen as a "data" field, and is serialized.
to_binary(Schema, Term) -> 
    Response = vice_encode:to_binary(Schema, Term),
    zlib:zip(Response).
    
to_binary_version(Version, Schema, Term) ->
    (Version >=0 andalso Version < 256) orelse throw({invalid_version_number, Version}),
    Response = to_binary(Schema, Term),
    <<Version:8/integer, Response/binary>>.
        
from_binary(Schema, Binary) -> 
    Binary1 = zlib:unzip(Binary),
    {Value, Rest} = vice_decode:from_binary(Schema, Binary1),
    (Rest == <<>>) orelse throw({bytes_left_over, Rest}),
    Value.

from_binary_version(Versions, Binary) -> 
    <<Version:8/integer, Rest/binary>> = Binary,
    case Version of 
        131 -> {Version, binary_to_term(Binary)};
        _   -> 
            Schema = proplists:get_value(Version, Versions),
            {Version, from_binary(Schema, Rest)}
    end.