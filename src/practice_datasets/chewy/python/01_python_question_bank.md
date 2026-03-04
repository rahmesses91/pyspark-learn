# Chewy — Python Question Bank (Data Engineering)

**Scope:** Pure Python only (no pandas). String manipulation, text parsing, text manipulation, and working with lists of text. Problems are framed for data-engineering tasks (logs, delimited data, cleaning, validation).

---

## 1. String manipulation

---

**Q1.1**  
Given a string that may contain leading/trailing spaces and multiple spaces between words (e.g. `"  order_id   12345  shipped  "`), return a single string with exactly one space between words and no leading/trailing spaces. Implement without using `str.split()` and re-joining (do it with a loop or character-by-character logic).

order_status = order_status.strip()

---

**Q1.2**  
A log line is formatted as `LEVEL|timestamp|message` (e.g. `ERROR|2024-01-15T10:30:00|Connection timeout`). Write a function that takes such a string and returns a tuple `(level, timestamp, message)`. If the line does not contain exactly two `|` separators, return `None` or raise a clear exception.



---

**Q1.3**  
Given a string that represents a product name (e.g. `"Premium Dog Food 5lb"`), return the same string with every word capitalized (first letter uppercase, rest lowercase). Handle multiple spaces so the output has normalized single spaces between words.

---

**Q1.4**  
You have a string that might be a numeric ID (e.g. `"12345"` or `" 00123 "`). Write a function that returns the integer value if the string (after stripping) represents a non-negative integer, and returns `None` otherwise. Do not use `int()` in a try/except; validate character-by-character (digits only, optional leading spaces).

---

**Q1.5**  
Given a string and a character, return the count of how many times that character appears in the string. Then, write a variant that returns the list of indices (0-based) where the character appears.

---

**Q1.6**  
A field may contain pipe-delimited values that can include empty segments (e.g. `"a|b||d|"`). Split the string by `|` and return a list of segments. Preserve empty strings between or after delimiters so the result has the correct length (e.g. 5 elements for `"a|b||d|"`).

---

## 2. Text parsing

---

**Q2.1**  
Parse a line that looks like a CSV field: it may be quoted (e.g. `"hello, world"`) or unquoted (e.g. `hello`). If quoted, the inner commas are part of the value and quotes are escaped as `""`. Write a function that takes such a single field string and returns the unquoted, unescaped value. Assume the input is either a quoted or unquoted field, not a full row.

---

**Q2.2**  
A log entry is: `[2024-03-01 12:00:00] user_id=1001 action=click product_id=302`. Write a function that parses this and returns a dictionary: `{"timestamp": "...", "user_id": "1001", "action": "click", "product_id": "302"}`. Keys and values are always in the form `key=value`; value has no spaces (or extend to support quoted values).

---

**Q2.3**  
Given a string that looks like a URL path with query params (e.g. `"/search?category=Pet+Food&page=2"`), return a dictionary of query parameters. Keys and values should be decoded (e.g. `+` or `%20` → space, `%26` → `&`). Handle missing `?` or empty query string by returning an empty dict.

---

**Q2.4**  
A line is in key-value format with multiple separators: `key1: value1; key2: value2; key3: value3`. Keys and values may have surrounding spaces. Return a dictionary mapping key → value (stripped). Handle empty or malformed segments (e.g. missing `:`) by skipping them or returning a default.

---

**Q2.5**  
Parse a string that represents a list of integers in brackets, e.g. `"[1, 2, 3, 10]"`. Return a list of integers. If the string is malformed (e.g. invalid characters, unbalanced brackets), return `None` or raise. Use only string methods and loops (no `eval` or `ast.literal_eval`).

---

**Q2.6**  
A fixed-width line has fields at known start positions: column 0–5 is `id`, 6–15 is `name`, 16–25 is `status`. Given such a line (e.g. `"  123  Product X    active   "`), return a dict `{"id": "...", "name": "...", "status": "..."}` with values stripped. Generalize to a list of `(start, end, key)` so the same function works for different schemas.

---

## 3. Text manipulation and cleaning

---

**Q3.1**  
Given a list of strings that might be empty or contain only whitespace, return a new list with each string stripped and empty/whitespace-only entries removed. Preserve order.

---

**Q3.2**  
A string may contain invalid characters for a "safe" identifier: only letters, digits, and underscore. Replace any other character with underscore and collapse consecutive underscores into one. Return the cleaned string (e.g. `"user-id (new)"` → `"user_id_new"`).

---

**Q3.3**  
Given a string and a max length, truncate the string to that length. If truncated, append `"..."` so the total length does not exceed `max_length + 3`. Handle edge cases: empty string, length 0, string shorter than max.

---

**Q3.4**  
Normalize line endings: given a string that might contain `\r\n`, `\r`, or `\n`, return a string where all line breaks are a single `\n`. Do not use `replace` in a chain; do a single pass (e.g. loop or regex once).

---

**Q3.5**  
Given two strings, return the longest common prefix (e.g. `"order_123"` and `"order_456"` → `"order_"`). Return empty string if no common prefix.

---

**Q3.6**  
A string represents a decimal number with possible spaces or commas (e.g. `"1,234.56"` or `"1 234.56"`). Return a string that can be safely converted to float: remove spaces and commas, keep one optional decimal point. If the result is not a valid number string, return `None`.

---

## 4. Lists and series of texts

---

**Q4.1**  
Given a list of log lines (strings), return only the lines that contain a given substring (e.g. `"ERROR"`). Return a new list; do not modify the original.

---

**Q4.2**  
Given a list of strings, return a list of the same length where each element is the first word of the corresponding string (words separated by whitespace). If a string is empty or only spaces, return empty string for that element.

---

**Q4.3**  
Given a list of strings that are pipe-delimited (e.g. `["a|b|c", "x|y|z"]`), return a list of lists: each inner list is the split of the corresponding string. Assume no quoted pipes inside fields.

---

**Q4.4**  
Given a list of strings, find the string that appears most frequently. Return that string. If there is a tie, return the one that first reaches that count. If the list is empty, return `None` or raise.

---

**Q4.5**  
Given a list of strings (e.g. product names or IDs), remove duplicates while preserving the order of first occurrence. Implement without using `set` (use a loop and a structure to track “seen”).

---

**Q4.6**  
Given a list of strings that look like `"key=value"` pairs (with possible spaces), parse them into a single dictionary. If a key repeats, later values overwrite earlier ones. Strip keys and values. Handle malformed entries (e.g. no `=`) by skipping or using a default.

---

**Q4.7**  
Given a list of lines (e.g. log lines), return a new list where each line is reversed character-by-character. Then, write a variant that reverses the order of words in each line (words separated by spaces) but keeps characters within each word unchanged.

---

**Q4.8**  
Concatenate a list of strings with a delimiter (e.g. `["a", "b", "c"]` with `"|"` → `"a|b|c"`). Write it without using `str.join()` (use a loop). Handle empty list (return `""`) and single-element list.

---

**Q4.9**  
Given a list of strings, group them by length (number of characters). Return a dictionary: key = length, value = list of strings that have that length. Preserve relative order within each group.

---

**Q4.10**  
Given a list of strings and a character, return the count of how many times that character appears across all strings combined. Then, return the list of strings that contain that character at least once, in original order.

---

## 5. Try/except and validation (data engineering)

---

**Q5.1**  
Write a function that takes a string and tries to convert it to an integer. Return the integer if conversion succeeds. If the string is not a valid integer (e.g. `"12.5"`, `"abc"`), catch the exception and return `None` (or a default value). Use a try/except and avoid swallowing other errors.

---

**Q5.2**  
Write a function that takes a string and returns a boolean: `True` if it can be parsed as a non-negative integer (after strip), `False` otherwise. Use try/except around `int()` and handle `ValueError`. Do not use regex.

---

**Q5.3**  
Parse a string that should be in ISO-like date format `YYYY-MM-DD`. Return a tuple `(year, month, day)` as integers if valid; if the format is wrong or the date is invalid, catch the error and return `None`. Use only string slicing and `int()` (no `datetime`), and validate ranges (month 1–12, day 1–31 or proper max per month if you want to be strict).

---

**Q5.4**  
Given a list of strings that should represent numbers, return a list of floats. For any element that cannot be converted to float, insert `None` in the result at that position (so the result has the same length as the input). Use try/except per element.

---

**Q5.5**  
Read a “config” string with lines like `key = value`. Parse into a dict; strip keys and values. If a line does not contain `=`, skip it. Use try/except so that if any single line causes an error during processing, you skip that line and continue with the rest, and return the dictionary built from valid lines.

---

## Summary by topic

| Topic              | Question IDs   |
|--------------------|----------------|
| String manipulation| 1.1 – 1.6     |
| Text parsing       | 2.1 – 2.6     |
| Text manipulation  | 3.1 – 3.6     |
| Lists of text      | 4.1 – 4.10    |
| Try/except & validation | 5.1 – 5.5 |

Use any Python file or notebook to write your solutions. No solutions are provided in this bank.
