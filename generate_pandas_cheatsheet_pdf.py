#!/usr/bin/env python3
"""Generate pandas_cheatsheet_40_functions.pdf from the cheatsheet content."""

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle

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


def main():
    doc = SimpleDocTemplate(
        "pandas_cheatsheet_40_functions.pdf",
        pagesize=letter,
        leftMargin=0.35 * inch,
        rightMargin=0.35 * inch,
        topMargin=0.3 * inch,
        bottomMargin=0.3 * inch,
    )
    styles = getSampleStyleSheet()
    cell_style = ParagraphStyle(
        name="Cell",
        parent=styles["Normal"],
        fontSize=7,
        leading=8,
    )

    # Build single table: Category | Function | Description
    data = [["Category", "Function", "Description"]]
    for cat, items in CONTENT:
        for i, (code, desc) in enumerate(items):
            cat_cell = cat if i == 0 else ""
            data.append([
                cat_cell,
                Paragraph(f'<font name="Courier" size="7">{code}</font>', cell_style),
                desc,
            ])

    t = Table(data, colWidths=[1.5 * inch, 3.8 * inch, 2.2 * inch])
    t.setStyle(TableStyle([
        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 8),
        ("FONT", (0, 1), (0, -1), "Helvetica", 7),
        ("FONT", (1, 1), (1, -1), "Courier", 7),
        ("FONT", (2, 1), (2, -1), "Helvetica", 7),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E0E0E0")),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 1),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 1),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8F8F8")]),
    ]))

    title_style = ParagraphStyle(
        name="Title",
        parent=styles["Normal"],
        fontSize=11,
        fontName="Helvetica-Bold",
        spaceAfter=2,
    )

    story = [
        Paragraph("Pandas Cheatsheet — 40 Essential Functions", title_style),
        t,
        Paragraph(
            "1-page • 40 functions • Assessments",
            ParagraphStyle(name="F", parent=styles["Normal"], fontSize=6, textColor="gray", spaceBefore=2)
        ),
    ]
    doc.build(story)
    print("Created: pandas_cheatsheet_40_functions.pdf")


if __name__ == "__main__":
    main()
