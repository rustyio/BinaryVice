-module (test).
-compile(export_all).

-record (my_object, {field1, field2, field3}).

go() ->
    sync:go(),
    test(atom@, atom),
    test(binary@, <<"binary">>),
    test(boolean@, true),
    test(float@, 3.14159),
    test(function@, fun() -> ok end),
    test(integer@, -3276),
    test({integer@, 2}, 300),
    test(pid@, self()),
    test(reference@, make_ref()),
    test(string@, "hello"),
    test(tuple@, {a, b, c}),
    test(list@, [a, b, c]),
    test({atom@, string@, list@}, {atom, "string", [a, b, c]}),
    test([atom@, string@, list@], [atom, "string", [a, b, c]]),
    test({list@, atom@}, [a, b, c]),
    test(#my_object { field1=atom@, field2=integer@, field3=boolean@ }, #my_object { field1=hello, field2=5, field3=true }),
    
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