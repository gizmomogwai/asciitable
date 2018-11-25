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

import std.stdio; // TODO
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

        return colored.leftJustifyFormattedString(row < lines.length ? lines[row] : "", width);
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

    auto render(ulong row, string leftBorder, string columnSeparator, string rightBorder)
    {
        auto res = leftBorder ~ cells.map!(cell => cell.render(row))
            .join(columnSeparator) ~ rightBorder;
        return res;
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

class Parts
{
    string horizontal;
    string vertical;
    string crossing;

    string topLeft;
    string topRight;
    string bottomLeft;
    string bottomRight;
    string topCrossing;
    string leftCrossing;
    string bottomCrossing;
    string rightCrossing;
    string headerHorizontal;
    string headerCrossing;
    string headerLeftCrossing;
    string headerRightCrossing;
    this(string horizontal, string vertical, string crossing, string topLeft, string topRight, string bottomLeft,
            string bottomRight, string topCrossing, string bottomCrossing,
            string leftCrossing, string rightCrossing, string headerHorizontal,
            string headerCrossing, string headerLeftCrossing, string headerRightCrossing)
    {
        this.horizontal = horizontal;
        this.headerHorizontal = headerHorizontal;
        this.vertical = vertical;
        this.crossing = crossing;
        this.headerCrossing = headerCrossing;
        this.topLeft = topLeft;
        this.topRight = topRight;
        this.bottomLeft = bottomLeft;
        this.bottomRight = bottomRight;
        this.topCrossing = topCrossing;
        this.bottomCrossing = bottomCrossing;
        this.leftCrossing = leftCrossing;
        this.headerLeftCrossing = headerLeftCrossing;
        this.rightCrossing = rightCrossing;
        this.headerRightCrossing = headerRightCrossing;
    }
}

class AsciiParts : Parts
{
    this()
    {
        super("-", "|", "+", "+", "+", "+", "+", "+", "+", "+", "+", "=", "+", "+", "+");
    }
}

class UnicodeParts : Parts
{
    this()
    {
        super("─", "│", "┼", "┌", "┐", "└", "┘", "┬", "┴",
                "├", "┤", "═", "╪", "╞", "╡");
    }
}
/// the formatter collects format parameters and prints the table
struct Formatter
{
    private AsciiTable table;
    private string mPrefix = null;
    private bool mRowSeparator = false;
    private bool mHeaderSeparator = false;
    private bool mColumnSeparator = false;
    private ulong[] mColumnWidths = null;
    private Parts mParts = null;
    private bool mTopBorder = false;
    private bool mLeftBorder = false;
    private bool mBottomBorder = false;
    private bool mRightBorder = false;
    this(AsciiTable newTable, Parts parts = new AsciiParts)
    {
        table = newTable;
        mParts = parts;
    }

    auto parts(Parts parts)
    {
        mParts = parts;
        return this;
    }

    auto borders(bool borders)
    {
        topBorder(borders);
        leftBorder(borders);
        bottomBorder(borders);
        rightBorder(borders);
        return this;
    }

    /// Switch top and bottom border
    auto horizontalBorders(bool borders)
    {
        topBorder(borders);
        bottomBorder(borders);
        return this;
    }
    /// Switch left and right border
    auto verticalBorders(bool borders)
    {
        leftBorder(borders);
        rightBorder(borders);
        return this;
    }

    auto topBorder(bool topBorder)
    {
        mTopBorder = topBorder;
        return this;
    }

    auto leftBorder(bool leftBorder)
    {
        mLeftBorder = leftBorder;
        return this;
    }

    auto bottomBorder(bool bottomBorder)
    {
        mBottomBorder = bottomBorder;
        return this;
    }

    auto rightBorder(bool rightBorder)
    {
        mRightBorder = rightBorder;
        return this;
    }
    /// change the prefix that is printed in front of each row
    auto prefix(string newPrefix)
    {
        mPrefix = newPrefix;
        return this;
    }

    auto separators(bool active)
    {
        columnSeparator(active);
        rowSeparator(active);
        headerSeparator(active);
        return this;
    }
    /// change the separator between columns, use null for no separator
    auto columnSeparator(bool columnSeparator)
    {
        mColumnSeparator = columnSeparator;
        return this;
    }
    /// change the separator between rows, use null for no separator
    auto rowSeparator(bool rowSeparator)
    {
        mRowSeparator = rowSeparator;
        return this;
    }

    auto headerSeparator(bool headerSeparator)
    {
        mHeaderSeparator = headerSeparator;
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

    private auto renderRow(Row row)
    {
        string[] lines = [];
        for (int i = 0; i < row.height; ++i)
        {
            lines ~= row.render(i, mLeftBorder ? mParts.vertical : "", mColumnSeparator
                    ? mParts.vertical : "", mRightBorder ? mParts.vertical : "");
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

    string calcHorizontalSeparator(string normal, string left, string middle, string right)
    {
        return (mLeftBorder ? left : "") ~ table.rows[0].cells.map!(
                cell => normal.replicate(cell.width)).join(mColumnSeparator
                ? middle : normal) ~ (mRightBorder ? right : "");
    }
    /// Convert to tabular presentation
    string toString()
    {
        updateCellWidths();
        auto rSeparator = mRowSeparator ? calcHorizontalSeparator(mParts.horizontal,
                mParts.leftCrossing, mParts.crossing, mParts.rightCrossing) : null;
        auto hSeparator = mHeaderSeparator ? calcHorizontalSeparator(mParts.headerHorizontal,
                mParts.headerLeftCrossing, mParts.headerCrossing, mParts.headerRightCrossing) : null;
        auto prefix = mPrefix ? mPrefix : "";
        string[] lines = [];
        if (mTopBorder)
        {
            lines ~= calcHorizontalSeparator(mParts.horizontal, mParts.topLeft,
                    mParts.topCrossing, mParts.topRight);
        }
        foreach (idx, row; table.rows)
        {
            auto newLines = toString(table, row, idx == table.rows.length - 1,
                    hSeparator, rSeparator).map!(line => prefix ~ line);
            foreach (newLine; newLines)
            {
                lines ~= newLine;
            }
        }
        if (mBottomBorder)
        {
            lines ~= calcHorizontalSeparator(mParts.horizontal,
                    mParts.bottomLeft, mParts.bottomCrossing, mParts.bottomRight);
        }
        return lines.join("\n");
    }

    private auto toString(AsciiTable table, Row row, bool last,
            string headerSeparator, string rowSeparator)
    {
        if (row.cells.length != table.nrOfColumns)
        {
            throw new Exception("row %s not fully filled".format(row));
        }
        auto res = renderRow(row);
        if (last)
        {
            return res;
        }
        else
        {
            if (mHeaderSeparator)
            {
                if (row.header)
                {
                    return res ~ headerSeparator;
                }
            }
            if (mRowSeparator)
            {
                return res ~ rowSeparator;
            }
        }
        return res;
    }
}

@("emtpy table") unittest
{
    new AsciiTable(2).format.to!string;
}

///
@("example") unittest
{
    import unit_threaded;
    import std.conv;

    // dfmt off
    auto table = new AsciiTable(2)
       .header.add("HA").add("HB")
       .row.add("C").add("D")
       .row.add("E").add("F")
       .table;
  
    auto f1 = table
       .format
       .parts(new UnicodeParts)
       .borders(true)
       .separators(true)
       .to!string;
    // dfmt on
    std.stdio.writeln(f1);
    f1.shouldEqual(`┌──┬──┐
│HA│HB│
╞══╪══╡
│C │D │
├──┼──┤
│E │F │
└──┴──┘`);

    // dfmt off
   auto f2 = table
       .format
       .parts(new UnicodeParts)
       .prefix("  ")
       .rowSeparator(true)
       .to!string;
   // dfmt on
    f2.shouldEqual(`  HAHB
  ─────
  C D 
  ─────
  E F `);
    // dfmt off
    auto f3 = table
       .format
       .parts(new UnicodeParts)
       .columnSeparator(true)
       .to!string;
    // dfmt on
    f3.shouldEqual(`HA│HB
C │D 
E │F `);
}

///
@("multiline cells") unittest
{
    import unit_threaded;

    auto table = new AsciiTable(2).row.add("1\n2").add("3").row.add("4").add("5\n6").table;
    auto f = table.format.prefix("test:").to!string;
    f.shouldEqual(`test:13
test:2 
test:45
test: 6`);
}

///
@("headers") unittest
{
    import unit_threaded;

    auto table = new AsciiTable(1).header.add("1").row.add(2).table;
    auto f1 = table.format.headerSeparator(true).rowSeparator(true)
        .topBorder(true).bottomBorder(true).to!string;
    f1.shouldEqual(`-
1
=
2
-`);
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
