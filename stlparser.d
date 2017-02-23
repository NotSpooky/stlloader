module stlparser;

void main (string [] args) {
    assert (args.length == 2, `No filename given`);
    import std.stdio;
    import std.algorithm;
    auto file = File (args [1]);
    auto lines = file
        .byLineCopy;
    import std.regex : ctRegex, matchFirst;
    auto solidRegex  = ctRegex!`^solid\s+(?:\"(?:\\.|[^\\"])*\")?$`;
    import std.exception : enforce;
    import std.string : strip;
    enforce (!lines.empty && lines.front.strip.matchFirst (solidRegex)
    /**/ , `ASCII stl file doesn't start with 'solid '`);
    lines.popFront ();
    import std.array : Appender, split;
    Appender!(float []) facets   = [];
    Appender!(float []) vertices = [];
    foreach (line; lines) {
        // Tries each action until one returns true.
        void matchSwitch (bool delegate () [] actions) {
            foreach (action; actions) {
                if (action()) return;
            }
        }
        // Splits a string with floats separated by spaces to the floats.
        static auto ref toFloats (in string toParse) {
            import std.conv : to;
            return toParse.split(' ').map!(n => n.to!float);
        }
        line = line.strip;
        enum floatsRegex = `((?:[+-]?(?:\d*[.])?\d+\s*){3})`;
        matchSwitch ([
            () { return line.tryMatch!(`^facet\s+normal\s+` ~ floatsRegex ~ `$`)
            /**/ (facet  => facets   ~= toFloats (facet)); },
            () { return line.tryMatch!(`^vertex\s+` ~ floatsRegex ~ `$`)
            /**/ (vertex => vertices ~= toFloats (vertex)); },
            () { return line.tryMatch!(`facet(.+)`) (n => n.writeln);}
        ]);
    }
    `vertices: `.writeln;
    vertices.data.length.writeln;
    `facets: `.writeln;
    facets.data.length.writeln;
}


private bool tryMatch (string regexExpression)(in string line
/**/ , void delegate (string) action) {
    import std.regex : ctRegex, matchFirst;
    auto matchedLine = line.matchFirst (ctRegex!regexExpression);
    if (!matchedLine.empty) { // Matches.
        action (matchedLine [1]);
        return true;
    } else {
        return false;
    }
}
