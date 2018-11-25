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
import std.algorithm;
import std.range;
import std.conv;
import colored;

class Cell
{
    AsciiTable table;
    Row row;
    string[] lines;
    ulong width;
    this(AsciiTable table, Row row, string formatted)
    {
        import std.array;

        this.table = table;
        this.row = row;
        this.lines = formatted.split("\n");
        this.width = lines.map!(line => line.unformattedLength).maxElement;
    }

    ulong height()
    {
        return lines.length;
    }

    string render(ulong row)
    {
        return (row < lines.length ? lines[row] : "").leftJustifyFormattedString(width);
    }

    override string toString()
    {
        return super.toString ~ " { lines: %s }".format(lines);
    }
}

class Row
{
    AsciiTable table;
    ulong nrOfColumns;
    bool header;
    Cell[] cells;
    public ulong height = 0;

    this(AsciiTable table, ulong nrOfColumns, bool header)
    {
        this.table = table;
        this.nrOfColumns = nrOfColumns;
        this.header = header;
    }

    auto add(V)(V v)
    {
        if (cells.length == nrOfColumns)
        {
            throw new Exception("too many elements in row nrOfColumns=%s cells=%s".format(nrOfColumns,
                    cells.length));
        }

        auto cell = new Cell(table, this, v.to!string);
        cells ~= cell;
        this.height = max(height, cell.height);
        return this;
    }

    auto row()
    {
        return table.row();
    }

    auto format()
    {
        return table.format();
    }

    auto render(ulong row, string columnSeparator)
    {
        if (!columnSeparator)
        {
            columnSeparator = "";
        }
        return columnSeparator ~ cells.map!(cell => cell.render(row))
            .join(columnSeparator) ~ columnSeparator;
    }

    auto width(string columnSeparator)
    {
        return cells.fold!((memo,
                cell) => memo + cell.width)(0UL) + (cells.length + 1) * columnSeparator.length;
    }

    override string toString()
    {
        return super.toString ~ " { nrOfColumns: %s, cells: %s }".format(nrOfColumns, cells);
    }
}
/++
 + Build your table and later format it
 +/
class AsciiTable
{
    size_t nrOfColumns;
    Row[] rows;

    /++ create a new asciitable
   + Params:
   +     minimumWidths = minimum widths of the columns. columns are adjusted so that all entries of a column fit.
   +/
    this(size_t nrOfColumns)
    {
        this.nrOfColumns = nrOfColumns;
    }

    /// Open a row
    auto row()
    {
        return add(new Row(this, nrOfColumns, false));
    }

    auto header()
    {
        return add(new Row(this, nrOfColumns, true));
    }

    private auto add(Row row)
    {
        rows ~= row;
        return row;
    }
    /// create formatter to fine tune tabular presentation
    Formatter format()
    {
        return Formatter(this);
    }

}

/// the formatter collects format parameters and prints the table
struct Formatter
{
    private AsciiTable table;
    private string mPrefix = null;
    private string mRowSeparator = null;
    private string mHeaderSeparator = null;
    private string mColumnSeparator = null;
    private ulong[] mColumnWidths = null;
    this(AsciiTable newTable)
    {
        table = newTable;
    }
    /// change the prefix that is printed in front of each row
    auto prefix(string newPrefix)
    {
        mPrefix = newPrefix;
        return this;
    }

    /// change the separator between columns, use null for no separator
    auto columnSeparator(string s)
    {
        mColumnSeparator = s;
        return this;
    }
    /// change the separator between rows, use null for no separator
    auto rowSeparator(string s)
    {
        mRowSeparator = s;
        return this;
    }

    auto headerSeparator(string s)
    {
        mHeaderSeparator = s;
        return this;
    }

    auto columnWidths(ulong[] widths)
    {
        if (widths.length != table.nrOfColumns)
        {
            throw new Exception("Wrong number of widths");
        }
        mColumnWidths = widths;
        return this;
    }

    private string calcSeparatorRow(size_t length, string s)
    {
        string res = "";
        for (size_t i = 0; i < length; ++i)
        {
            res ~= s;
        }
        return res;
    }

    private auto renderRow(Row row, string[] lines)
    {
        for (int i = 0; i < row.height; ++i)
        {
            lines ~= row.render(i, mColumnSeparator);
        }
        return lines;
    }

    private void updateCellWidths()
    {
        if (table.rows.length == 0)
        {
            return;
        }
        for (int i = 0; i < table.rows[0].cells.length; ++i)
        {
            ulong width = mColumnWidths ? mColumnWidths[i] : 0;
            for (int j = 0; j < table.rows.length; ++j)
            {
                width = max(width, table.rows[j].cells[i].width);
            }
            for (int j = 0; j < table.rows.length; ++j)
            {
                table.rows[j].cells[i].width = width;
            }
        }
    }
    /// Convert to tabular presentation
    string toString()
    {
        updateCellWidths();
        ulong width = table.rows[0].width(mColumnSeparator);

        auto rSeparator = mRowSeparator ? mRowSeparator.replicate(width) : null;
        auto hSeparator = mHeaderSeparator ? mHeaderSeparator.replicate(width) : null;
        auto prefix = mPrefix ? mPrefix : "";
        auto lines = rSeparator ? [rSeparator] : [];
        return table.rows.fold!((memo, row) => toString(memo, table, row,
                hSeparator, rSeparator))(lines).map!(line => prefix ~ line).join("\n");
    }

    private auto toString(string[] lines, AsciiTable table, Row row,
            string hSeparator, string rSeparator)
    {
        if (row.cells.length != table.nrOfColumns)
        {
            throw new Exception("row %s not fully filled".format(row));
        }
        lines = renderRow(row, lines);
        if (row.header && hSeparator)
        {
            lines ~= hSeparator;
        }
        else if (rSeparator)
        {
            lines ~= rSeparator;
        }
        return lines;
    }
}

///
@("example") unittest
{
    import unit_threaded;
    import std.conv;

    auto table = new AsciiTable(2).row.add("1").add("2").row.add("3").add("4").table;
    auto f1 = table.format.to!string;
    f1.shouldEqual("12\n34");

    auto f2 = table.format.prefix("  ").rowSeparator("-").to!string;
    f2.shouldEqual("  --\n  12\n  --\n  34\n  --");

    auto f3 = table.format.prefix("  ").columnSeparator("|").to!string;
    f3.shouldEqual("  |1|2|\n  |3|4|");

    auto f4 = table.format.prefix("  ").columnSeparator("|").rowSeparator("-").to!string;
    f4.shouldEqual("  -----\n  |1|2|\n  -----\n  |3|4|\n  -----");
}

///
@("multiline cells") unittest
{
    import unit_threaded;

    auto table = new AsciiTable(2).row.add("1\n2").add("3").row.add("4").add("5\n6").table;
    auto f = table.format.prefix("test:").to!string;
    f.shouldEqual("test:13\ntest:2 \ntest:45\ntest: 6");
}

///
@("headers") unittest
{
    import unit_threaded;

    auto table = new AsciiTable(1).header.add("1").row.add(2).table;
    auto f1 = table.format.headerSeparator("=").rowSeparator("-").to!string;
    f1.shouldEqual("-\n1\n=\n2\n-");
}

@("wrong usage of ascii table") unittest
{
    import unit_threaded;

    new AsciiTable(2).row.add("1").add("2").add("3").shouldThrow!Exception;
}

@("auto expand columns") unittest
{
    import unit_threaded;

    new AsciiTable(1).row.add("test").format.columnWidths([10])
        .to!string.shouldEqual("test      ");
}

@("row not fully filled") unittest
{
    import unit_threaded;

    new AsciiTable(2).row.add("test").format.to!string.shouldThrow!Exception;
}
