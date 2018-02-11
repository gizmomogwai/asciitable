/++
 + Asciitable to nicely format tables of strings.
 +
 + Authors: Christian Koestlin
 + Copyright: Copyright © 2018, Christian Köstlin
 + License: MIT
 +/

module asciitable;

public import asciitable.packageversion;

import std.string;

struct Row
{
    string[] columns;
    this(string[] data)
    {
        this.columns = data;
    }
}

/++
 + The workhorse of the module.
 +/
struct AsciiTable
{
    ulong[] minimumWidths;
    Row[] rows;

    this(W...)(W minimumWidths)
    {
        this.minimumWidths = [minimumWidths];
    }

    /// Add a row of strings
    AsciiTable add(V...)(V values)
    {
        if (values.length != minimumWidths.length)
        {
            throw new Exception("All rows must have length %s".format(minimumWidths.length));
        }
        rows ~= Row([values]);
        return this;
    }

    /// Convert to tabular presentation
    string toString(string linePrefix = "", string separator = "")
    {
        import std.algorithm;
        import std.string;

        foreach (row; rows)
        {
            foreach (idx, column; row.columns)
            {
                minimumWidths[idx] = max(minimumWidths[idx], column.length);
            }
        }
        string res = "";
        foreach (row; rows)
        {
            if (res.length > 0)
            {
                res ~= "\n";
            }
            res ~= linePrefix ~ separator;
            foreach (idx, column; row.columns)
            {
                res ~= leftJustify(column, minimumWidths[idx], ' ') ~ separator;
            }
        }
        return res;
    }
}

///
@("example") unittest
{
    import unit_threaded;

    AsciiTable(1, 2, 3).add("1", "2", "3").add("4", "5", "6").toString("prefix",
            "|").shouldEqual("prefix|1|2 |3  |\n" ~ "prefix|4|5 |6  |");
}

@("wrong usage of ascii table") unittest
{
    import unit_threaded;

    AsciiTable(1, 1, 1).add("1", "2").shouldThrow!Exception;
}

@("auto expand columns") unittest
{
    import unit_threaded;

    AsciiTable(1).add("test").toString.shouldEqual("test");
}
