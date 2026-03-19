#!/usr/bin/env python3
"""
Generate python_datastructures_cheatsheet.pdf — str, list, set, dict, tuple, regex.
Aligned with src/python_core/data_structures and src/python_core/regex READMEs.
Single A4 page, 3-column layout (tuned for print).
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
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

# A4: 210×297 mm — extra vertical space vs US Letter; slightly narrower width
_A4_W_IN = A4[0] / 72.0
MARGIN_LR_IN = 0.28
MARGIN_TB_IN = 0.26
MARGIN_LR = MARGIN_LR_IN * inch
MARGIN_TB = MARGIN_TB_IN * inch
PAGE_USABLE = (_A4_W_IN - 2 * MARGIN_LR_IN) * inch
GAP = 0.10 * inch
COL_W = (PAGE_USABLE - 2 * GAP) / 3

# Typography tuned for A4 — larger body + padding so the page fills vertically
CODE_PT = 8
HEAD_PT = 9
HEADER_ROW_PT = HEAD_PT + 2  # section title row


def a4_lead_in_spacer(estimated_story_height_pt, max_pad_pt=200):
    """Push block down so whitespace is split top/bottom (ReportLab flows from top only)."""
    usable_pt = A4[1] - 2 * (MARGIN_TB_IN * 72.0)
    slack = usable_pt - estimated_story_height_pt
    pad = max(0, min(slack / 2.0, max_pad_pt))
    return Spacer(1, pad)


def make_section_table(title, items, para_style, section_width=None, code_pt=CODE_PT, head_pt=HEAD_PT):
    w = section_width if section_width is not None else COL_W
    cw = w * 0.54
    dw = w * 0.46
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
        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", HEADER_ROW_PT),
        ("FONT", (0, 1), (0, -1), "Courier", code_pt),
        ("FONT", (1, 1), (1, -1), "Helvetica", code_pt),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E0E0E0")),
        ("SPAN", (0, 0), (-1, 0)),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9F9F9")]),
    ]))
    return t


def main():
    out = "python_datastructures_cheatsheet.pdf"
    doc = SimpleDocTemplate(
        out,
        pagesize=A4,
        leftMargin=MARGIN_LR,
        rightMargin=MARGIN_LR,
        topMargin=MARGIN_TB,
        bottomMargin=MARGIN_TB,
    )
    styles = getSampleStyleSheet()
    cell_style = ParagraphStyle(
        name="CellDS",
        parent=styles["Normal"],
        fontSize=CODE_PT,
        leading=CODE_PT + 3,
    )
    title_style = ParagraphStyle(
        name="TitleDS",
        parent=styles["Normal"],
        fontSize=15,
        fontName="Helvetica-Bold",
        spaceAfter=10,
        leading=18,
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

    # Tuned estimate: if too low, PDF gains a 2nd page — if too high, extra bottom whitespace
    story = [
        a4_lead_in_spacer(575, max_pad_pt=190),
        Paragraph(
            "Python: str, list, set, dict, tuple + regex (re) — A4",
            title_style,
        ),
        # Row 1: balance heights; tuples shortest in middle
        row3(
            make_section_table(CONTENT[0][0], CONTENT[0][1], cell_style),
            make_section_table(CONTENT[4][0], CONTENT[4][1], cell_style),
            make_section_table(CONTENT[2][0], CONTENT[2][1], cell_style),
        ),
        Spacer(1, 16),
        # Row 2: lists + dict + regex
        row3(
            make_section_table(CONTENT[1][0], CONTENT[1][1], cell_style),
            make_section_table(CONTENT[3][0], CONTENT[3][1], cell_style),
            make_section_table(CONTENT[5][0], CONTENT[5][1], cell_style),
        ),
        Spacer(1, 14),
        Paragraph(
            "~80 ops • str, tuple, set | list, dict, regex • A4 • DE-focused",
            ParagraphStyle(name="FDS", parent=styles["Normal"], fontSize=8, textColor="gray", leading=9),
        ),
    ]
    doc.build(story)
    print(f"Created: {out}")


if __name__ == "__main__":
    main()
