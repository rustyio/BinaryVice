-module (test).
-compile(export_all).

-record (my_object, {field1, field2, field3}).

go() ->
    sync:go(),
    test(
        {'$integer$', {hello, '$atom$', '$string$'}}, 
        {1, {hello, my_atom, "My String"}}
    ),
    
    test(
        #my_object { field1 = '$atom$', field2='$integer$', field3='$list$' },
        #my_object { field1 = my_atom, field2=42, field3=[1,2,3] }
    ).
    
    
    
test(Schema, Term) ->
    io:format("Term: ~p~n", [Term]),
    B1 = term_to_binary(Term),
    B2 = vice:to_binary(Schema, Term),
    io:format("term_to_binary -> size: ~p~n", [size(B1)]),
    io:format("~p~n", [B1]),
    io:format("vice -> size: ~p~n", [size(B2)]),
    io:format("~p~n~n", [B2]),
    ok.
    
      
