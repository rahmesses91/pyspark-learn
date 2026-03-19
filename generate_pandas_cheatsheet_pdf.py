#!/usr/bin/env python3
"""Generate pandas_cheatsheet_40_functions.pdf from the cheatsheet content."""

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle, Spacer

CONTENT = [
    ("Data Loading & Inspection", [
        ('pd.read_csv("file.csv")', "Load CSV"),
        ('pd.read_json("data.json")', "Load JSON"),
        ("df.info()", "Schema + nulls"),
        ("df.head(10)", "Preview rows"),
        ("df.sample(5)", "Random sample"),
        ("df.shape", "Rows/columns"),
        ("df.describe()", "Summary stats"),
    ]),
    ("Selecting & Filtering", [
        ("df['col']", "Select column"),
        ("df[['a','b']]", "Select multiple columns"),
        ("df[df['age'] > 30]", "Boolean filter"),
        ("df[(df['age']>18) & (df['country']=='US')]", "Multi-condition"),
        ('df.query("country==\'US\'")', "SQL-style filter"),
        ("df[df['age'].between(20,30)]", "Range filter"),
    ]),
    ("Cleaning & Transforming", [
        ("df.dropna(subset=['id'])", "Drop missing"),
        ("df.fillna(0)", "Fill missing"),
        ("df.drop_duplicates(subset=['id'])", "Deduplicate"),
        ("df.duplicated()", "Check duplicates"),
        ("df.columns.difference(['id'])", "Exclude columns"),
        ("df.reset_index(drop=True)", "Reset index"),
        ("df.rename(columns={'a':'A'})", "Rename"),
        ("df.drop(columns=['col'])", "Drop column"),
        ("df.replace({'A':1})", "Replace values"),
        ("np.where(df['x']>0,1,0)", "Conditional column"),
    ]),
    ("Type Handling", [
        ("df['id'].astype('Int64')", "Cast type"),
        ("pd.to_datetime(df['ts'])", "To datetime"),
        ("df['ts'].dt.date", "Extract date"),
        ("df['ts'].dt.year", "Extract year"),
    ]),
    ("Aggregation & Grouping", [
        ("df.groupby('cat')['sales'].sum()", "Group + sum"),
        ("df.groupby('id').agg({'a':'sum','b':'count'})", "Multi-agg"),
        ("df['id'].count()", "Count"),
        ("df['user_id'].nunique()", "Unique count"),
        ("df['country'].value_counts()", "Frequency"),
        ("df.sort_values('sales', ascending=False)", "Sort"),
    ]),
    ("Joining & Combining", [
        ("pd.merge(a, b, on='id', how='left')", "SQL join"),
        ("df1.join(df2, how='left')", "Index join"),
        ("pd.concat([df1, df2])", "Stack DataFrames"),
    ]),
    ("Advanced Operations", [
        ("df['ma7'] = df['sales'].rolling(7).mean()", "Rolling window"),
        ("df['r'] = df.groupby('cat')['sales'].rank()", "Rank"),
        ("df.pivot_table(values='sales', index='cat', columns='region')", "Pivot"),
        ("df['x2'] = df['x'].apply(lambda x: x*2)", "Apply"),
        ("df['email'].str.lower()", "String ops"),
        ("df.loc[df['age']<0, 'age'] = 0", "Update rows"),
    ]),
]

# Column width for each half of the page (letter = 8.5", minus margins)
COL_WIDTH = 3.65 * inch
CODE_WIDTH = 2.2 * inch
DESC_WIDTH = 1.4 * inch


def make_section_table(title, items, code_style):
    """Build a compact 2-column table for one section (Function | Description)."""
    data = [[Paragraph(f'<b>{title}</b>', code_style), ""]]
    for code, desc in items:
        data.append([
            Paragraph(f'<font name="Courier" size="9">{code}</font>', code_style),
            desc,
        ])
    t = Table(data, colWidths=[CODE_WIDTH, DESC_WIDTH])
    t.setStyle(TableStyle([
        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 10),
        ("FONT", (0, 1), (0, -1), "Courier", 9),
        ("FONT", (1, 1), (1, -1), "Helvetica", 9),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E0E0E0")),
        ("SPAN", (0, 0), (-1, 0)),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8F8F8")]),
    ]))
    return t


def main():
    doc = SimpleDocTemplate(
        "pandas_cheatsheet_40_functions.pdf",
        pagesize=letter,
        leftMargin=0.4 * inch,
        rightMargin=0.4 * inch,
        topMargin=0.35 * inch,
        bottomMargin=0.35 * inch,
    )
    styles = getSampleStyleSheet()
    code_style = ParagraphStyle(
        name="Cell",
        parent=styles["Normal"],
        fontSize=9,
        leading=10,
    )

    title_style = ParagraphStyle(
        name="Title",
        parent=styles["Normal"],
        fontSize=14,
        fontName="Helvetica-Bold",
        spaceAfter=6,
    )

    story = [Paragraph("Pandas Cheatsheet — 40 Essential Functions", title_style)]

    # Pair sections side by side: (Data Loading, Selecting), (Cleaning, Type), (Aggregation, Joining), (Advanced,)
    pairs = [
        (CONTENT[0], CONTENT[1]),   # Data Loading | Selecting & Filtering
        (CONTENT[2], CONTENT[3]),   # Cleaning | Type Handling
        (CONTENT[4], CONTENT[5]),   # Aggregation | Joining
        (CONTENT[6], None),         # Advanced (full width)
    ]

    for left, right in pairs:
        t_left = make_section_table(left[0], left[1], code_style)
        if right:
            t_right = make_section_table(right[0], right[1], code_style)
            row = Table([[t_left, t_right]], colWidths=[COL_WIDTH, COL_WIDTH])
            row.setStyle(TableStyle([
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (0, -1), 0),
                ("RIGHTPADDING", (0, 0), (0, -1), 6),
                ("LEFTPADDING", (1, 0), (1, -1), 6),
                ("RIGHTPADDING", (1, 0), (1, -1), 0),
            ]))
            story.append(row)
        else:
            story.append(t_left)
        story.append(Spacer(1, 4))

    story.append(Paragraph(
        "1-page • 40 functions • Assessments",
        ParagraphStyle(name="F", parent=styles["Normal"], fontSize=8, textColor="gray")
    ))

    doc.build(story)
    print("Created: pandas_cheatsheet_40_functions.pdf")


if __name__ == "__main__":
    main()
