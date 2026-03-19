# Python Regular Expressions (regex)

This directory contains learning materials for **regular expressions** in Python using the built-in `re` module. Regex is used for pattern matching, search, extraction, and replacement in text—essential for log parsing, data validation, and cleaning.

---

## What is regex?

A **regular expression** (regex) is a sequence of characters that defines a *search pattern*. Instead of matching literal text (e.g. `"error"`), you describe *shapes* of text:

- "One or more digits" → `\d+`
- "A word, then @, then a word, then a dot and 2–4 letters" → email-like pattern
- "Whitespace or punctuation" → `[\s\W]+`

The Python **`re`** module provides functions to:

| Goal | Use |
|------|-----|
| Check if the **whole string** matches a pattern | `re.match()` |
| Find the **first** occurrence anywhere in the string | `re.search()` |
| Find **all** non-overlapping matches | `re.findall()` |
| **Replace** matches with new text | `re.sub()` |
| **Split** a string by a pattern | `re.split()` |

---

## Printable cheatsheet (repo root)

- **`python_datastructures_cheatsheet.pdf`** (A4) includes a **Regex (`re`)** column (match, search, findall, sub, split, compile, groups, common pattern syntax).
- Regenerate: `python3 generate_python_datastructures_pdf.py` (requires `reportlab`).

## Contents

| File | Description |
|------|-------------|
| `README.md` | This file — overview, pattern reference, and usage guide |
| `regex_basics.ipynb` | Runnable examples: match, search, findall, sub, and common patterns |

---

## How to use regex in Python

### 1. Import the module

```python
import re
```

### 2. Choose the right function

| Function | When to use | Returns |
|----------|-------------|--------|
| `re.match(pattern, string)` | Pattern must match **from the start** of the string | Match object or `None` |
| `re.search(pattern, string)` | Pattern can appear **anywhere** in the string | Match object or `None` |
| `re.findall(pattern, string)` | Get **every** match as a list | List of strings (or tuples if groups) |
| `re.sub(pattern, repl, string)` | **Replace** each match with `repl` | New string |
| `re.split(pattern, string)` | **Split** by the pattern | List of substrings |

### 3. Work with match objects

When `re.match()` or `re.search()` finds something, they return a **match object** (not the string itself):

```python
m = re.search(r"\d+", "Order 12345 shipped")
if m:
    print(m.group())   # "12345"  — the matched text
    print(m.start())   # 6        — start index
    print(m.end())     # 11       — end index
```

- `m.group()` — entire match  
- `m.group(1)`, `m.group(2)` — first, second capturing group  
- `m.groups()` — tuple of all groups  

---

## Essential pattern syntax

Patterns are written as **raw strings** (`r"..."`) so backslashes are not interpreted by Python.

### Character classes

| Pattern | Meaning | Example |
|---------|---------|---------|
| `.` | Any character (except newline by default) | `r"a.c"` → "abc", "a1c" |
| `\d` | Digit `[0-9]` | `r"\d+"` → "123" |
| `\D` | Non-digit | |
| `\w` | Word character: letter, digit, underscore | `r"\w+"` → "hello_1" |
| `\W` | Non-word character | |
| `\s` | Whitespace (space, tab, newline) | |
| `\S` | Non-whitespace | |
| `[abc]` | One of a, b, or c | |
| `[a-z]` | Any lowercase letter | |
| `[^abc]` | Any character *except* a, b, c | |

### Quantifiers

| Pattern | Meaning | Example |
|---------|---------|---------|
| `*` | Zero or more | `r"\d*"` |
| `+` | One or more | `r"\d+"` → one or more digits |
| `?` | Zero or one | `r"colou?r"` → "color" or "colour" |
| `{n}` | Exactly n | `r"\d{4}"` → exactly 4 digits |
| `{n,}` | n or more | `r"\d{2,}"` |
| `{n,m}` | Between n and m | `r"\d{2,4}"` |

### Anchors and boundaries

| Pattern | Meaning |
|---------|---------|
| `^` | Start of string (or line in multiline mode) |
| `$` | End of string (or line in multiline mode) |
| `\b` | Word boundary (between `\w` and `\W` or start/end) |

### Groups and alternation

| Pattern | Meaning |
|---------|---------|
| `( ... )` | Capturing group — use `m.group(1)` to get the text |
| `(?: ... )` | Non-capturing group (group for logic, not for extraction) |
| `A|B` | Match A or B |

### Escaping

- In a pattern, `*`, `.`, `?`, `[`, `]`, `(`, `)`, `\`, etc. have special meaning.
- To match a literal `*`, use `\*` (or `re.escape("*")` for any literal string).

---

## Common data-engineering examples

### Check if string contains digits

```python
import re
has_digits = bool(re.search(r"\d+", "Order 123"))  # True
first_number = re.search(r"\d+", "Order 123")
first_number.group() if first_number else None     # "123"
```

### Extract all email-like substrings

```python
pattern = r"\w+@\w+\.\w{2,4}"
emails = re.findall(pattern, "Contact support@example.com or sales@co.org")
# ['support@example.com', 'sales@co.org']
```

### Extract order ID and date

```python
text = "Order #12345 shipped on 2024-01-15"
order_id = re.search(r"#(\d+)", text)
date = re.search(r"(\d{4}-\d{2}-\d{2})", text)
(order_id.group(1) if order_id else None, date.group(1) if date else None)
# ('12345', '2024-01-15')
```

### Normalize: replace non-alphanumeric runs with one underscore

```python
re.sub(r"[^a-zA-Z0-9]+", "_", "Hello,  world! How are you?").strip("_")
# "Hello_world_How_are_you"
```

### Split by multiple delimiters

```python
re.split(r"[\s,;]+", "a, b; c  d")
# ['a', 'b', 'c', 'd']
```

### Filter log lines by level (e.g. ERROR or WARN)

```python
lines = ["INFO: started", "ERROR: failed", "WARN: retry", "INFO: done"]
error_warn = [s for s in lines if re.search(r"^(ERROR|WARN):", s)]
# ['ERROR: failed', 'WARN: retry']
```

---

## Tips and pitfalls

1. **Use raw strings** — Write patterns as `r"\d+"` so `\d` is not interpreted as an escape by Python.
2. **match vs search** — `match()` only checks from the **beginning** of the string; `search()` finds the pattern **anywhere**.
3. **Always check for `None`** — `re.search()` and `re.match()` return `None` when there is no match; call `.group()` only after checking.
4. **Greedy vs non-greedy** — `*` and `+` are greedy (match as much as possible). Use `*?` or `+?` for non-greedy (match as little as possible).
5. **Compile for reuse** — If you use the same pattern many times, `re.compile(pattern)` once and call `.search()`, `.findall()`, etc. on the compiled object for better performance.

---

## Related topics

- **Strings** (`data_structures/strings/`) — `str` methods for simple splits, replaces, and checks
- **Python question bank** (`practice_datasets/chewy/python/01_python_question_bank.md`) — Section 6 has regex practice questions

Use **string methods** when the logic is simple (fixed delimiters, known prefixes); use **regex** when you need flexible patterns (variable formats, optional parts, or extraction of subpatterns).
