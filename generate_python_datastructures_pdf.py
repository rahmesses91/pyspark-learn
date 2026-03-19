#!/usr/bin/env python3
"""
Generate python_datastructures_cheatsheet.pdf — str, list, set, dict, tuple, regex.
Aligned with src/python_core/data_structures and src/python_core/regex READMEs.
Single letter page, 3-column layout (same engine as pandas cheatsheet).
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle, Spacer

# Order: row1 = str, list, set | row2 = dict, tuple, regex
CONTENT = [
    ("Strings (str)", [
        ('s.strip() / lstrip() / rstrip()', "Trim whitespace/chars"),
        ("s.lower() / upper() / title()", "Case transforms"),
        ('s.split(",") / rsplit()', "Split to list"),
        ('",".join(parts)', "List to string"),
        ("s.replace(old, new)", "Replace substring"),
        ("s.startswith() / endswith()", "Prefix/suffix check"),
        ("s.find() / rfind()", "Index or -1"),
        ("s.count(sub)", "Count occurrences"),
        ("s.isdigit() / isalpha() / isalnum()", "Char-type checks"),
        ("s.partition(sep)", "Head, sep, tail"),
        ("s.removeprefix() / removesuffix()", "Py3.9+ trim affix"),
        ("s.zfill(n) / ljust() / rjust()", "Pad / align"),
        ("f\"{x}\" / format()", "Interpolation"),
        ("s[1:4] / s[::-1]", "Slice / reverse"),
    ]),
    ("Lists (list)", [
        ("lst.append(x)", "Add end"),
        ("lst.extend(iterable)", "Add many"),
        ("lst.insert(i, x)", "Insert at i"),
        ("lst.pop([i])", "Remove & return"),
        ("lst.remove(x)", "Remove first x"),
        ("lst.clear()", "Empty list"),
        ("lst.sort(key=fn, reverse=)", "Sort in-place"),
        ("sorted(lst)", "New sorted list"),
        ("lst.reverse()", "Reverse in-place"),
        ("lst.index(x) / count(x)", "Find / count"),
        ("lst.copy() / lst[:]", "Shallow copy"),
        ("[x*2 for x in lst]", "List comprehension"),
        ("[x for x in lst if cond]", "Filter comp"),
        ("list(map(fn, lst))", "Transform"),
        ("list(filter(pred, lst))", "Filter iterator"),
    ]),
    ("Sets (set)", [
        ("s.add(x)", "One element"),
        ("s.update(iterable)", "Many elements"),
        ("s.remove(x) / discard(x)", "Remove (error / safe)"),
        ("s.pop() / clear()", "Arbitrary pop / empty"),
        ("a | b", "Union"),
        ("a & b", "Intersection"),
        ("a - b", "Difference"),
        ("a ^ b", "Symmetric difference"),
        ("x in s", "O(1) membership"),
        ("s.issubset(t) / issuperset()", "Containment"),
        ("s.isdisjoint(t)", "No overlap"),
        ("set(iterable)", "Dedupe (unordered)"),
        ("frozenset(s)", "Immutable set"),
        ("{x for x in it if cond}", "Set comprehension"),
    ]),
    ("Dictionaries (dict)", [
        ("d[key] = val", "Assign"),
        ("d.get(k, default)", "Safe read"),
        ("d.setdefault(k, default)", "Get or set"),
        ("d.keys() / values() / items()", "Views"),
        ("d.update(other)", "Merge in-place"),
        ("d | other / |=", "Merge Py3.9+"),
        ("d.pop(k) / popitem()", "Remove pair"),
        ("del d[k] / clear()", "Delete / empty"),
        ("k in d", "Key membership"),
        ("dict.fromkeys(keys, v)", "Init keys"),
        ("{k: f(v) for k,v in d.items()}", "Dict comp"),
        ("{r['id']: r for r in rows}", "Lookup table"),
        ("copy() / deepcopy()", "Shallow / deep"),
    ]),
    ("Tuples (tuple)", [
        ("t.count(x) / index(x)", "Only tuple methods"),
        ("a, b, c = t", "Unpack"),
        ("a, *mid, z = t", "Star unpack"),
        ("(x,) single", "One-element tuple"),
        ("t1 + t2", "Concatenate"),
        ("x in t", "Membership"),
        ("tuple(iterable)", "Construct"),
        ("d[(region, sku)]", "Composite dict key"),
        ("return a, b", "Multi return"),
        ("sorted(t)", "Sort → list"),
        ("hash(t) if no mutables", "Hashable record"),
    ]),
    ("Regex (re module)", [
        ("re.match(pat, s)", "Start of string"),
        ("re.search(pat, s)", "First anywhere"),
        ("re.findall(pat, s)", "All matches"),
        ("re.sub(pat, repl, s)", "Replace"),
        ("re.split(pat, s)", "Split on pattern"),
        ("re.compile(pat)", "Reuse pattern"),
        ("m.group() / group(1)", "Whole / group"),
        ("m.groups()", "All groups tuple"),
        (r'r"\d+" raw', "Raw string for \\d"),
        (r". ^ $ \b", "Any, start, end, word"),
        (r"\d \w \s \D \W \S", "Digit, word, space"),
        ("+ * ? {n,m}", "Quantifiers"),
        ("[abc] [a-z] [^0-9]", "Character class"),
        ("( ) | (?: )", "Group / alt / non-cap"),
        ("*? +?", "Non-greedy"),
    ]),
]

PAGE_USABLE = 7.5 * inch
GAP = 0.12 * inch
COL_W = (PAGE_USABLE - 2 * GAP) / 3


def make_section_table(title, items, para_style, section_width=None, code_pt=6, head_pt=7):
    w = section_width if section_width is not None else COL_W
    cw = w * 0.58
    dw = w * 0.42
    data = [[Paragraph(f"<b>{title}</b>", para_style), ""]]
    for code, desc in items:
        safe = (
            code.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        )
        data.append([
            Paragraph(f'<font name="Courier" size="{code_pt}">{safe}</font>', para_style),
            desc,
        ])
    t = Table(data, colWidths=[cw, dw])
    t.setStyle(TableStyle([
        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", head_pt + 1),
        ("FONT", (0, 1), (0, -1), "Courier", code_pt),
        ("FONT", (1, 1), (1, -1), "Helvetica", code_pt),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E0E0E0")),
        ("SPAN", (0, 0), (-1, 0)),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 2),
        ("RIGHTPADDING", (0, 0), (-1, -1), 2),
        ("TOPPADDING", (0, 0), (-1, -1), 0),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9F9F9")]),
    ]))
    return t


def main():
    out = "python_datastructures_cheatsheet.pdf"
    doc = SimpleDocTemplate(
        out,
        pagesize=letter,
        leftMargin=0.28 * inch,
        rightMargin=0.28 * inch,
        topMargin=0.22 * inch,
        bottomMargin=0.22 * inch,
    )
    styles = getSampleStyleSheet()
    cell_style = ParagraphStyle(
        name="CellDS",
        parent=styles["Normal"],
        fontSize=6,
        leading=7,
    )
    title_style = ParagraphStyle(
        name="TitleDS",
        parent=styles["Normal"],
        fontSize=11,
        fontName="Helvetica-Bold",
        spaceAfter=3,
        leading=12,
    )
    col_widths_3 = [COL_W, GAP, COL_W, GAP, COL_W]

    def row3(a, b, c):
        inner = Table([[a, "", b, "", c]], colWidths=col_widths_3)
        inner.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 0),
            ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ("TOPPADDING", (0, 0), (-1, -1), 0),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ]))
        return inner

    story = [
        Paragraph(
            "Python: str, list, set, dict, tuple + regex (re) — 1 page",
            title_style,
        ),
        row3(
            make_section_table(CONTENT[0][0], CONTENT[0][1], cell_style),
            make_section_table(CONTENT[1][0], CONTENT[1][1], cell_style),
            make_section_table(CONTENT[2][0], CONTENT[2][1], cell_style),
        ),
        Spacer(1, 2),
        row3(
            make_section_table(CONTENT[3][0], CONTENT[3][1], cell_style),
            make_section_table(CONTENT[4][0], CONTENT[4][1], cell_style),
            make_section_table(CONTENT[5][0], CONTENT[5][1], cell_style),
        ),
        Spacer(1, 1),
        Paragraph(
            "~80 ops • str, list, set, dict, tuple, re • DE-focused",
            ParagraphStyle(name="FDS", parent=styles["Normal"], fontSize=6, textColor="gray", leading=7),
        ),
    ]
    doc.build(story)
    print(f"Created: {out}")


if __name__ == "__main__":
    main()
