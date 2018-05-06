int main(string[] args)
{
    import std.stdio;
    import asciitable;

    AsciiTable(20, 20).add("hello", "world").add("here", "we are").toString("prefix", "|").writeln;
    return 0;
}
