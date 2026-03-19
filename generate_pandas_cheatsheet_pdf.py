#!/usr/bin/env python3
"""Generate pandas_cheatsheet_40_functions.pdf — single A4 page, dense 3-col layout."""

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle, Spacer

CONTENT = [
    ("Data Loading & Inspection", [
        ('pd.read_csv("file.csv")', "Load CSV"),
        ('pd.read_json("data.json")', "Load JSON"),
        ('pd.read_excel("file.xlsx")', "Load Excel"),
        ("df.info()", "Schema + nulls"),
        ("df.head(10)", "Preview rows"),
        ("df.tail(5)", "Last rows"),
        ("df.sample(5)", "Random sample"),
        ("df.shape", "Rows/columns"),
        ("df.dtypes", "Column types"),
        ("df.columns", "Column names"),
        ("df.describe()", "Summary stats"),
    ]),
    ("Selecting & Filtering", [
        ("df['col']", "Select column"),
        ("df[['a','b']]", "Select multiple columns"),
        ("df.iloc[0:5]", "Select by position"),
        ("df.loc[df['x']>0]", "Select by label/condition"),
        ("df[df['age'] > 30]", "Boolean filter"),
        ("df[(df['age']>18) & (df['country']=='US')]", "Multi-condition"),
        ('df.query("country==\'US\'")', "SQL-style filter"),
        ("df[df['age'].between(20,30)]", "Range filter"),
        ("df[df['id'].isin([1,2,3])]", "Is-in filter"),
    ]),
    ("Cleaning & Transforming", [
        ("df.dropna(subset=...) / how='all' / inplace=True", "Drop missing rows"),
        ("df.fillna(0) / fillna(..., inplace=True)", "Fill missing"),
        ("df.ffill()", "Forward fill"),
        ("df.drop_duplicates(...) / duplicated()", "Dedupe / flag dupes"),
        ("df.columns.difference([...])", "Exclude columns"),
        ("df.reset_index(drop=True) / ..., inplace=True", "Reset index"),
        ("df.rename(columns={...}) / ..., inplace=True", "Rename cols"),
        ("df.drop(columns=[...]) / ..., inplace=True", "Drop cols"),
        ("df.replace({...})", "Replace values"),
        ("df.assign(new_col=...)", "Add column"),
        ("np.where(cond, a, b)", "Conditional column"),
    ]),
    ("Type Handling", [
        ("df['id'].astype('Int64')", "Cast type"),
        ("df['id'].astype(str)", "To string"),
        ("pd.to_datetime(df['ts'])", "To datetime"),
        ("df['ts'].dt.date", "Extract date"),
        ("df['ts'].dt.year", "Extract year"),
        ("df['ts'].dt.month", "Extract month"),
        ("df['ts'].dt.dayofweek", "Day of week"),
    ]),
    ("Aggregation & Grouping", [
        ("df.groupby('cat')['sales'].sum()", "Single col group"),
        ("df.groupby(['cat','region'])['sales'].sum()", "Multi-col group"),
        ("df.groupby(['cat','region']).agg({...})", "Multi-col + multi-agg"),
        ("df.groupby('cat').mean()", "Group mean"),
        ("df.groupby('id').agg({'a':'sum','b':'count'})", "Multi-agg"),
        ("df.groupby('cat').size()", "Group size"),
        ("df['id'].count()", "Count"),
        ("df['user_id'].nunique()", "Unique count"),
        ("df['country'].value_counts()", "Frequency"),
        ("df.sort_values('sales', ascending=False)", "Sort"),
        ("df.sort_values('sales', inplace=True)", "Sort in-place"),
        ("df.nlargest(5, 'sales')", "Top N rows"),
    ]),
    ("Joining & Combining", [
        ("pd.merge(a, b, on='id', how='left')", "Left join"),
        ("pd.merge(a, b, on='id', how='right')", "Right join"),
        ("pd.merge(a, b, on='id', how='inner')", "Inner join"),
        ("pd.merge(a, b, on='id', how='outer')", "Outer join"),
        ("pd.merge(a, b, how='cross')", "Cross join"),
        ("df1.join(df2, how='left')", "Index join"),
        ("pd.concat([df1, df2])", "Stack DataFrames"),
        ("pd.concat([df1, df2], axis=1)", "Concat columns"),
    ]),
    ("Advanced — Window & Cumulative", [
        ("df['ma7'] = df['sales'].rolling(7).mean()", "Rolling mean"),
        ("df['lag'] = df['x'].shift(1)", "Lag column"),
        ("df['r'] = df.groupby('cat')['sales'].rank()", "Rank"),
        ("df.groupby('cat').cumcount()", "Cumcount per group"),
        ("df['x'].cumsum()", "Cumulative sum"),
        ("df.groupby('cat')['x'].cumsum()", "Cumsum per group"),
        ("df['x'].cummax()", "Cumulative max"),
        ("df['x'].cummin()", "Cumulative min"),
        ("df['x'].pct_change()", "Pct change"),
        ("df['x'].diff(1)", "Diff (lag diff)"),
    ]),
    ("Advanced — Reshape & Strings", [
        ("df.pivot_table(values='sales', index='cat', columns='region')", "Pivot"),
        ("df.melt(id_vars=['id'])", "Wide to long"),
        ("df.explode('col')", "Explode list col"),
        ("df['x2'] = df['x'].apply(lambda x: x*2)", "Apply"),
        ("df['email'].str.lower()", "String lower"),
        ("df['col'].str.contains('x')", "String contains"),
        ("df['col'].str.split(',')", "String split"),
        ("df.loc[df['age']<0, 'age'] = 0", "Update rows"),
    ]),
]

# A4 width minus side margins → usable width; 3 columns + gaps
_A4_W_IN = A4[0] / 72.0
MARGIN_LR_IN = 0.28
MARGIN_TB_IN = 0.22
MARGIN_LR = MARGIN_LR_IN * inch
MARGIN_TB = MARGIN_TB_IN * inch
PAGE_USABLE = (_A4_W_IN - 2 * MARGIN_LR_IN) * inch
GAP = 0.10 * inch
COL_W = (PAGE_USABLE - 2 * GAP) / 3

CODE_PT = 7
HEAD_PT = 8
HEADER_ROW_PT = HEAD_PT + 1


def make_section_table(title, items, para_style, section_width=None, code_pt=CODE_PT, head_pt=HEAD_PT):
    """Compact Function | Description table; section_width defaults to one of 3 columns."""
    w = section_width if section_width is not None else COL_W
    cw = w * 0.54
    dw = w * 0.46
    data = [[Paragraph(f'<b>{title}</b>', para_style), ""]]
    for code, desc in items:
        safe = code.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        data.append([
            Paragraph(f'<font name="Courier" size="{code_pt}">{safe}</font>', para_style),
            desc,
        ])
    t = Table(data, colWidths=[cw, dw])
    t.setStyle(TableStyle([
        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", HEADER_ROW_PT),
        ("FONT", (0, 1), (0, -1), "Courier", code_pt),
        ("FONT", (1, 1), (1, -1), "Helvetica", code_pt),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E0E0E0")),
        ("SPAN", (0, 0), (-1, 0)),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 2),
        ("RIGHTPADDING", (0, 0), (-1, -1), 2),
        ("TOPPADDING", (0, 0), (-1, -1), 1),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 1),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9F9F9")]),
    ]))
    return t


def main():
    doc = SimpleDocTemplate(
        "pandas_cheatsheet_40_functions.pdf",
        pagesize=A4,
        leftMargin=MARGIN_LR,
        rightMargin=MARGIN_LR,
        topMargin=MARGIN_TB,
        bottomMargin=MARGIN_TB,
    )
    styles = getSampleStyleSheet()
    cell_style = ParagraphStyle(
        name="Cell",
        parent=styles["Normal"],
        fontSize=CODE_PT,
        leading=CODE_PT + 2,
    )

    title_style = ParagraphStyle(
        name="Title",
        parent=styles["Normal"],
        fontSize=12,
        fontName="Helvetica-Bold",
        spaceAfter=4,
        leading=14,
    )

    col_widths_3 = [COL_W, GAP, COL_W, GAP, COL_W]
    half_w = (PAGE_USABLE - GAP) / 2

    def row3(a, b, c):
        """One physical row: col | gap | col | gap | col."""
        inner = Table([[a, "", b, "", c]], colWidths=col_widths_3)
        inner.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 0),
            ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ("TOPPADDING", (0, 0), (-1, -1), 0),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ]))
        return inner

    def row2_wide(left, right):
        """Bottom row: two half-page section tables (Advanced split)."""
        inner = Table([[left, "", right]], colWidths=[half_w, GAP, half_w])
        inner.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 0),
            ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ("TOPPADDING", (0, 0), (-1, -1), 0),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ]))
        return inner

    story = [
        Paragraph("Pandas Cheatsheet — Essential Functions (A4)", title_style),
    ]

    # Row 1: shorter sections — balances height across page
    story.append(row3(
        make_section_table(CONTENT[0][0], CONTENT[0][1], cell_style),
        make_section_table(CONTENT[1][0], CONTENT[1][1], cell_style),
        make_section_table(CONTENT[3][0], CONTENT[3][1], cell_style),
    ))
    story.append(Spacer(1, 5))

    # Row 2: Cleaning | Aggregation | Joining
    story.append(row3(
        make_section_table(CONTENT[2][0], CONTENT[2][1], cell_style),
        make_section_table(CONTENT[4][0], CONTENT[4][1], cell_style),
        make_section_table(CONTENT[5][0], CONTENT[5][1], cell_style),
    ))
    story.append(Spacer(1, 5))

    # Row 3: Advanced — two half-width tables (full page width)
    story.append(row2_wide(
        make_section_table(CONTENT[6][0], CONTENT[6][1], cell_style, section_width=half_w),
        make_section_table(CONTENT[7][0], CONTENT[7][1], cell_style, section_width=half_w),
    ))

    story.append(Spacer(1, 3))
    story.append(Paragraph(
        "80+ ops • 3-column layout • A4",
        ParagraphStyle(name="F", parent=styles["Normal"], fontSize=6, textColor="gray", leading=7)
    ))

    doc.build(story)
    print("Created: pandas_cheatsheet_40_functions.pdf")


if __name__ == "__main__":
    main()
