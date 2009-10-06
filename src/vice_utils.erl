-module (vice_utils).
-export ([is_placeholder/1, ensure_matching_types/2]).

%%% - BINARY TO TERM - %%%

% is_placeholder(Schema, Term) - Return true if the provided Schema
% is a placeholder, meaning that we should decode the term. 
% Otherwise, return false.
is_placeholder(atom@) -> true;
is_placeholder(binary@) -> true;
is_placeholder({binary@, _}) -> true;
is_placeholder(bitstring@) -> true;
is_placeholder({bitstring@, _}) -> true;
is_placeholder(boolean@) -> true;
is_placeholder(float@) -> true;
is_placeholder(function@) -> true;
is_placeholder(integer@) -> true;
is_placeholder({integer@, _}) -> true;
is_placeholder(pid@) -> true;
is_placeholder(reference@) -> true;
is_placeholder(string@) -> true;
is_placeholder({string@, _}) -> true;
is_placeholder(list@) -> true;
is_placeholder({list@, _}) -> true;
is_placeholder(tuple@) -> true;
is_placeholder({tuple@, _}) -> true;
is_placeholder(dict@) -> true;
is_placeholder({dict@, _, _}) -> true;
is_placeholder(term@) -> true;
is_placeholder(_) -> false.

% is_placeholder(Schema, Term) - Return true if the provided Schema
% is a placeholder, meaning that we should encode the term. 
% Throw an exception if the Term does not match the expected type.
% Otherwise, return false.

ensure_matching_types(atom@, O) -> is_atom(O) orelse throw({not_an_atom, O});
ensure_matching_types(binary@, O) -> is_binary(O) orelse throw({not_a_binary, O});
ensure_matching_types({binary@, _}, O) -> is_binary(O) orelse throw({not_a_binary, O});
ensure_matching_types(bitstring@, O) -> is_bitstring(O) orelse throw({not_a_bitstring, O});
ensure_matching_types({bitstring@, _}, O) -> is_bitstring(O) orelse throw({not_a_bitstring, O});
ensure_matching_types(boolean@, O) -> is_boolean(O) orelse throw({not_a_boolean, O});
ensure_matching_types(float@, O) -> is_float(O) orelse throw({not_a_float, O});
ensure_matching_types(function@, O) -> is_function(O) orelse throw({not_a_function, O});
ensure_matching_types(integer@, O) -> is_integer(O) orelse throw({not_an_integer, O});
ensure_matching_types({integer@, _}, O) -> is_integer(O) orelse throw({not_an_integer, O});
ensure_matching_types(pid@, O) -> is_pid(O) orelse throw({not_a_pid, O});
ensure_matching_types(reference@, O) -> is_reference(O) orelse throw({not_a_reference, O});
ensure_matching_types(string@, O) -> is_list(O) orelse throw({not_a_string, O});
ensure_matching_types({string@, _}, O) -> is_list(O) orelse throw({not_a_string, O});
ensure_matching_types(list@, O) -> is_list(O) orelse throw({not_a_list, O});
ensure_matching_types({list@, _}, O) -> is_list(O) orelse throw({not_a_list, O});
ensure_matching_types(tuple@, O) -> is_tuple(O) orelse throw({not_a_tuple, O});
ensure_matching_types({tuple@, _}, O) -> is_tuple(O) orelse throw({not_a_tuple, O});
ensure_matching_types(dict@, O) -> is_tuple(O) orelse throw({not_a_dict, O});
ensure_matching_types({dict@, _, _}, O) -> is_tuple(O) orelse throw({not_a_dict, O});
ensure_matching_types(term@, _) -> true;
ensure_matching_types(Schema, _) -> throw({ensure_matching_types, unknown_type, Schema}).