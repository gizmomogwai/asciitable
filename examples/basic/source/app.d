int main(string[] args)
{
    import std.stdio;
    import asciitable;
    import colored;
    import std.string;
    import std.conv;

    import asciitable;
    import std.stdio;

    // dfmt off
    new AsciiTable(2)
        .row.add("hello").add("world")
        .row.add("here").add("we are")
        .format
        .columnSeparator(true)
        .leftBorder(true)
        .writeln;
    // dfmt on
    
    
    // dfmt off
    new AsciiTable(2)
      .row().add("helloworld".red.to!string ~ "\ntest").add("hello %s world".format("beautiful".red))
      .row().add("hi").add("there 1234567890\ntest")
      .row().add("table in table").add(
        new AsciiTable(2)
        .row().add("1".red.to!string).add("2".green.to!string)
        .row().add("3".blue.to!string).add("4".yellow.to!string)
        .format
        .columnSeparator(true)
        .rowSeparator(true)
        .parts(new UnicodeParts)
        .toString)
      .format
      .prefix("PREFIX:" )
      .columnSeparator(true)
      .rowSeparator(true)
      .writeln;
    // dfmt on
    return 0;
}
