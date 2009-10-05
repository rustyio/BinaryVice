-module (test).
-compile(export_all).

-record (my_object, {field1, field2, field3}).

go() ->
    up_to_date = sync:go(),
    datatypes_test(),
    versions_test().
    
datatypes_test() ->
    test([atom@, binary@, boolean@, integer@, {integer@, 1}, string@], [atom, <<"b">>, true, -42, 9, "string"]),
    test([float@, function@, pid@, reference@], [-3.14159, fun() -> ok end, self(), make_ref()]),
    test([tuple@, list@], [{a, b, c}, [a, b, c]]),
    test([{tuple@, atom@}, {list@, atom@}], [{a, b, c}, [a, b, c]]),
    test(#my_object { field1=atom@, field2=integer@, field3=boolean@ }, #my_object { field1=hello, field2=5, field3=true }),
    
    % Dicts...
    D = dict:new(),
    D1 = dict:store(key1, value1, D),
    D2 = dict:store(key2, value2, D1),
    test(dict@, D2),
    test({dict@, atom@, atom@}, D2).
    
test(Schema, Term) ->
    io:format("---~n"),
    io:format("     Schema: ~p~n", [Schema]),
    io:format("       Term: ~p~n", [Term]),
    B = vice:to_binary(Schema, Term),
    io:format("       size: ~p (~p orig.) ~n", [size(B), size(term_to_binary(Term))]),
    T = vice:from_binary(Schema, B),
    io:format("from_binary: ~p~n", [T]),
    Term == T orelse throw({not_equal, T, Term}).
    
versions_test() -> 
    V1 = vice:to_binary_version(1, atom@, my_atom),
    V2 = vice:to_binary_version(2, string@, "my_string"),
    V3 = term_to_binary({something_else}),
    Versions = [
        {1, atom@},
        {2, string@}
    ],
    
    {1, my_atom} = vice:from_binary_version(Versions, V1),
    {2, "my_string"} = vice:from_binary_version(Versions, V2),
    {131, {something_else}} = vice:from_binary_version(Versions, V3),
    io:format("Versions successful!"),
    ok.
    
    