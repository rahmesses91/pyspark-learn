#!/usr/bin/env python3
"""Generate pandas_cheatsheet_40_functions.pdf from the cheatsheet content."""

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem
from reportlab.lib.enums import TA_LEFT

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
        leftMargin=0.5 * inch,
        rightMargin=0.5 * inch,
        topMargin=0.4 * inch,
        bottomMargin=0.4 * inch,
    )
    styles = getSampleStyleSheet()
    story = []

    title_style = ParagraphStyle(
        name="CustomTitle",
        parent=styles["Heading1"],
        fontSize=14,
        spaceAfter=6,
    )
    heading_style = ParagraphStyle(
        name="SectionHeading",
        parent=styles["Heading2"],
        fontSize=10,
        spaceBefore=6,
        spaceAfter=3,
    )
    code_style = ParagraphStyle(
        name="Code",
        parent=styles["Normal"],
        fontName="Courier",
        fontSize=8,
        leftIndent=0,
        spaceAfter=1,
    )

    story.append(Paragraph("Pandas Cheatsheet — 40 Essential Functions (PDF-Ready)", title_style))
    story.append(Spacer(1, 4))

    for section_title, items in CONTENT:
        story.append(Paragraph(section_title, heading_style))
        for code, desc in items:
            text = f'<font name="Courier" size="8">{code}</font> — {desc}'
            story.append(Paragraph(text, code_style))
        story.append(Spacer(1, 2))

    story.append(Spacer(1, 4))
    story.append(Paragraph(
        "Optimized for 1-page printing • Minimal spacing • All 40 functions • Perfect for assessments",
        ParagraphStyle(name="Footer", parent=styles["Normal"], fontSize=7, textColor="gray")
    ))

    doc.build(story)
    print("Created: pandas_cheatsheet_40_functions.pdf")


if __name__ == "__main__":
    main()
