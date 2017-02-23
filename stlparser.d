module stlparser;

auto ref parseSTL (in string filename) {
    import std.stdio : File;
    auto file = File (filename);
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
        static void matchSwitch (bool delegate () [] actions) {
            foreach (action; actions) {
                if (action()) return;
            }
        }
        // Splits a string with floats separated by spaces to the floats.
        static auto ref toFloats (in string toParse) {
            import std.algorithm : map;
            import std.conv      : to;
            return toParse.split(' ').map!(n => n.to!float);
        }
        line = line.strip;
        enum floatsRegex = `((?:[+-]?(?:\d*[.])?\d+(?:e[+-]?\d+)?\s*){3})`;
        matchSwitch ([
            () { return line.tryMatch!(`^facet\s+normal\s+` ~ floatsRegex ~ `$`)
            /**/ (facet  => facets   ~= toFloats (facet)); },
            () { return line.tryMatch!(`^vertex\s+` ~ floatsRegex ~ `$`)
            /**/ (vertex => vertices ~= toFloats (vertex)); },
        ]);
    }
    auto returnVertices = vertices.data;
    auto returnFacets   = facets.data;
    import std.conv : text;
    enforce (returnVertices.length == returnFacets.length * 3
    /**/ , text (`There aren't 3 times as much vertices as facets: `
    /**/ , returnVertices, ` `, returnFacets.length)
    );
    import std.typecons : tuple;
    return tuple (returnVertices, returnFacets);
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
