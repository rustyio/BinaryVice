<h1>BinaryVice</h1>

<h2>What is BinaryVice?</h2>

BinaryVice allows you to serialize Erlang terms more efficiently than term_to_binary/1, so long as the Erlang terms have a repetitive structure, or "schema."

Consider a simple record defined as follows:

	-record(my_record, { n })
	
Behind the scenes, Erlang stores the record as a tuple:

	{my_record, 5000}
	
If you call term_to_binary on this tuple, Erlang needs to store information in the binary saying that:

1. The term is a tuple (1 byte)
2. The tuple contains one element (1 bytes for a small tuple, 4 for a large tuple)
3. The first element is an atom (1 byte)
4. The atom is 9 characters long (2 bytes)
5. The name of the atom, 'my_record' (9 bytes)
6. The second element is an integer (1 byte)
7. The value of the integer (4 bytes)

If you are keeping track, this means we have wasted 15 bytes of space in order to store 4 bytes of data. If your application stores or transmits millions or billions of terms, this adds up.

<h2>How does BinaryVice work?</h2>

BinaryVice allows you to specify a schema when you encode an element with placeholders for the information that will change. Continuing with the example above:

	% Our term...
	Term = #record { n = 5000 },
	
	% Our schema. Notice the 'integer@' placeholder 
	Schema = #record { n=integer@ },
	B = vice:to_binary(Schema, Term)
	
The binary produced by vice:to_binary/1 is 6 bytes, compared to 20 bytes returned by term_to_binary/1. There are placeholders for every Erlang primitive, plus some special ones for encoding a list or dictionary where all items have the same schema.

<h2>Versioning</h2>

The one rule about a schema is that it will eventually change. When it does, BinaryVice is ready. BinaryVice allows you to encode your term with a version number. Then, when you want to decode your data, you can pass BinaryVice a list of possible versions, and BinaryVice will choose the right one. The version number can be any integer from 0 to 255 except for 131, because this number is used to identify terms encoded by term_to_binary/1.

For example:

	-record(my_record1, { n }).
	-record(my_record2, { n, a}).
	
	...
	
	% Schemas...
	Schema1 = #my_record1 { n=integer@ },
	Schema2 = #my_record2 { n=integer@, a=atom@ }
	Schemas = {
		{1, Schema1},
		{2, Schema2}
	],
	
	% Encode using version 1...
	Term1 = #my_record1 { n = 5000 },
	B1 = vice:to_binary_version(1, Schema1, Term1),

	% Encode using version 2...
	Term2 = #my_record2 { n = 5000, a=version_two }
	B2 = vice:to_binary_version(2, Schema2, Term2),
	
	% Decode automatically detects whether our
	% term is version 1 or version 2.	
	
	% This returns {1, #my_record1 { n=5000}}.
	vice:from_binary_version(Schemas, B1),
	
	% And this returns {2, #my_record2 { n=5000, a=version_two}}.
	vice:from_binary_version(Schemas, B2),
	
	...


<h2>Drop-In Replacement</h2>

BinaryVice was built so that you can drop it into your current application without having to migrate your existing data. The vice:from_binary_version/2 function detects when a binary was encoded using term_to_binary/1 and returns the decoded term with version 131.

<h2>BinaryVice vs. term_to_binary/1</h2>

Based on simple tests, BinaryVice makes your data about 40% smaller than term_to_binary(Term), and about 10% smaller than term_to_binary(Term, [compressed]). 

BinaryVice is fast, but slower than term_to_binary(Term), but about 5 times faster than term_to_binary(Term, [compressed]). 

Actual results depend upon your data.

<h2>Interface</h2>

* <b>vice:to_binary(Schema, Term) -> B</b> - Encode a term using the provided schema.
* <b>vice:from_binary(Schema, B) -> Term</b> - Decode a binary using the provided schema.
* <b>vice:to_binary_version(Version, Schema, Term) -> B</b> - Encode a term using the provided schema, tagged with a version number.
* <b>vice:from_binary_version(Versions, Term) -> {Version, Term}</b> - Decode a versioned binary. Versions is a list of {Version, Schema}.

<h2>What's with the name?</h2>

It vaguely rhymes with <a href="http://en.wikipedia.org/wiki/Miami_Vice">Miami Vice</a>.

<h2>Disclaimer</h2>

Use this at your own risk, and test thoroughly. There may be some lurking corner cases that haven't been addressed.
