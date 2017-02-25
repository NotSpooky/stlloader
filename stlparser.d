module stlloader.stlparser;

auto ref parseSTL (in string filename) {
    import std.stdio : File;
    auto file = File (filename);
    import std.algorithm : map, find;
    import std.string : strip;
    auto lines = file
        .byLineCopy
        .map!strip;
    import std.regex : ctRegex, matchFirst;
    auto solidRegex  = ctRegex!`^solid\s+.*`;
    import std.exception : enforce;
    enforce (!lines.empty && lines.front.matchFirst (solidRegex)
    /**/ , `ASCII stl file doesn't start with 'solid '`);
    lines.popFront ();
    import std.array : Appender;
    Appender!(float []) facets   = [];
    Appender!(float []) vertices = [];
    foreach (line; lines) {
        /// Splits a string with floats separated by spaces to the floats.
        static auto ref toFloats (in string toParse) {
            import std.conv  : to;
            import std.regex : split;
            return toParse.split(ctRegex!`\s+`).map!(to!float);
        }
        enum floatsRegex = `((?:[+-]?(?:\d*[.])?\d+(?:e[+-]?\d+)?\s*){3})`;
        import std.stdio;

        [   // Adds facets and vertices to their respective Appender.
            () { return line.tryMatch!(`^facet\s+normal\s+` ~ floatsRegex ~ `$`)
            /**/ (facet  => facets   ~= toFloats (facet)); },
            //(facet => facet.writeln);},
            () { return line.tryMatch!(`^vertex\s+` ~ floatsRegex ~ `$`)
            /**/ (vertex => vertices ~= toFloats (vertex)); }
            //(vertex => vertex.writeln);}
        ].find!`a()`(true); // Tries each function until one returns true.
    }
    auto returnVertices = vertices.data;
    auto returnFacets   = facets.data;
    import std.conv : text;
    enforce ( returnVertices.length == returnFacets.length * 3
    /**/ , text (`There aren't 3 times as much vertices as facets: `
    /**/ , returnVertices.length, ` `, returnFacets.length) );
    import std.typecons : tuple;
    return tuple (returnVertices, returnFacets);
}

/// If the line matches the regexExpression, executes action and returns true,
/// else returns false.
private bool tryMatch 
/**/ (string regexExpression) (in string line, void delegate (string) action) {
    import std.regex : ctRegex, matchFirst;
    auto matchedLine = line.matchFirst (ctRegex!regexExpression);
    if (!matchedLine.empty) { // Matches.
        action (matchedLine [1]);
        return true;
    } else {
        return false;
    }
}
