"""
Chewy Interview Research — Domain A: Data Parsing & Cleaning

Medium-difficulty Python questions for Data Engineer / Analytics Engineer screens.
No Stack/Queue, no Heap. Focus: string manipulation, regex, recursion, dicts, validation.
"""

from typing import List, Dict, Any, Optional, Union

# ---------------------------------------------------------------------------
# Dataset requirements (in-memory or file-based) for questions in this category
# ---------------------------------------------------------------------------

DATASETS = {
    "env_file": {
        "description": "Multiline string or list of lines: KEY=value, optional # comments, blank lines",
        "sample": ["# config\nAPI_KEY=abc123\nDEBUG=true\n# end", "DB_HOST=localhost"],
    },
    "apache_log_line": {
        "description": "Single string: Apache common log format (IP - - [date] \"method path\" status size)",
        "sample": ['127.0.0.1 - - [01/Mar/2024:12:00:00 +0000] "GET /search?q=dog HTTP/1.1" 200 1234'],
    },
    "phone_strings": {
        "description": "List of strings: mixed phone formats (with spaces, dashes, parens, +1)",
        "sample": [["(555) 123-4567", "+1 555.123.4567", "5551234567", "555-1234"]],
    },
    "email_list_string": {
        "description": "Single string: comma- or semicolon-separated emails, possibly with spaces",
        "sample": ["a@b.com, invalid, c@d.co.uk;  e@f.org"],
    },
    "nested_dict_rows": {
        "description": "List of dicts with nested dicts/lists; keys may be dotted in output",
        "sample": [[{"user": {"id": 1, "name": "A"}, "tags": ["x", "y"]}]],
    },
    "category_typos": {
        "description": "List of strings: product/category names with common typos or variants",
        "sample": [["Dog Food", "dog food", "Cat Food", "Pet Food", "petfood"]],
    },
    "semicolon_delimited": {
        "description": "String: semicolon-delimited with optional quoted fields containing semicolons",
        "sample": ['"Smith; John"; 25; "NY; USA"'],
    },
    "text_with_numbers": {
        "description": "String containing mixed text and numbers (prices, IDs, quantities)",
        "sample": ["Order 12345: 2 items at $19.99 each, total 39.98"],
    },
    "version_strings": {
        "description": "List of strings: semver-like (major.minor.patch) or invalid",
        "sample": [["1.2.3", "2.0.0", "invalid", "1.0"]],
    },
    "log_lines_key_value": {
        "description": "List of strings: log lines with key=value pairs, values may be quoted",
        "sample": ['user_id=1001 action="click item" product_id=302'],
    },
    "delimited_lines_key_column": {
        "description": "List of pipe- or comma-delimited lines; key column index for dedup",
        "sample": [["id|name|score", "1|Alice|90", "2|Bob|80", "1|Alice|95"]],
    },
    "boolean_like_strings": {
        "description": "List of strings: yes/no, true/false, 1/0, on/off (mixed case)",
        "sample": [["yes", "FALSE", "1", "Off", "unknown"]],
    },
    "simple_table_string": {
        "description": "String: header row + data rows (comma or tab), first row = column names",
        "sample": ["name,age,city\nAlice,30,NY\nBob,25,LA"],
    },
    "free_text_with_dates": {
        "description": "List of strings: free text containing a date in YYYY-MM-DD or similar",
        "sample": ["Order placed on 2024-01-15", "Shipped 2024-02-20"],
    },
}

# ---------------------------------------------------------------------------
# Questions
# ---------------------------------------------------------------------------

QUESTIONS: List[Dict[str, Any]] = [
    {
        "id": "A01",
        "title": "Env-File Parser",
        "description": (
            "Parse a multiline env-file string (or list of lines). Extract KEY=value pairs; "
            "strip keys and values. Ignore lines that are blank or start with #. Return a dictionary."
        ),
        "core_concepts": ["String splitting", "Stripping", "Dictionary building", "Comment handling"],
        "why_chewy": "Config and feature flags in pipelines; env-based config is common.",
        "interviewer_evaluates": "Clean parsing, handling blank lines and comments without over-engineering.",
        "common_mistakes": "Not stripping values; treating # in the middle of a line as comment; mutating original.",
        "dataset_required": "env_file",
    },
    {
        "id": "A02",
        "title": "Apache-Style Log Line Parser",
        "description": (
            "Given a single Apache common log format string, parse and return a dict with keys: "
            "ip, date, method, path, status_code (integer). Handle malformed lines by returning None or raising."
        ),
        "core_concepts": ["Regex or string slicing", "Structured parsing", "Type conversion"],
        "why_chewy": "Server and CDN logs; debugging and analytics on request paths.",
        "interviewer_evaluates": "Accuracy of extraction; handling quoted request string and status/size.",
        "common_mistakes": "Splitting on space and breaking on path with spaces; not parsing date.",
        "dataset_required": "apache_log_line",
    },
    {
        "id": "A03",
        "title": "Phone Number Normalizer",
        "description": (
            "Given a list of phone number strings (with spaces, dashes, parens, optional +1), "
            "return a list of digits-only strings (e.g. 10 digits for US). Optionally strip leading country code."
        ),
        "core_concepts": ["String manipulation", "Regex or filter(str.isdigit)", "Edge cases"],
        "why_chewy": "Customer and vendor contact data normalization for dedup and validation.",
        "interviewer_evaluates": "Consistent output length; handling empty or invalid input.",
        "common_mistakes": "Leaving non-digits; inconsistent length (10 vs 11 with country code).",
        "dataset_required": "phone_strings",
    },
    {
        "id": "A04",
        "title": "Email List Validator and Splitter",
        "description": (
            "Parse a string of comma- or semicolon-separated emails (with possible spaces). "
            "Return two lists: valid emails and invalid entries. Define 'valid' (e.g. contains @, has domain)."
        ),
        "core_concepts": ["Split by multiple delimiters", "Validation logic", "Stripping"],
        "why_chewy": "Newsletter and notification pipelines; list hygiene.",
        "interviewer_evaluates": "Clear validity rules; handling mixed separators and spaces.",
        "common_mistakes": "Not normalizing separators; weak validation (e.g. only checking for @).",
        "dataset_required": "email_list_string",
    },
    {
        "id": "A05",
        "title": "Flatten Nested Dicts to CSV-Style Rows",
        "description": (
            "Given a list of dicts that may contain nested dicts/lists, flatten each dict into a single-level "
            "dict (e.g. user.name, tags.0) and return a list of flattened dicts suitable for CSV export."
        ),
        "core_concepts": ["Recursion", "Dictionary traversal", "Key path building"],
        "why_chewy": "Exporting JSON API responses or event payloads to tabular format.",
        "interviewer_evaluates": "Consistent key naming; handling lists (indexed keys) and varying depth.",
        "common_mistakes": "Hardcoding depth; not handling list elements; key collisions.",
        "dataset_required": "nested_dict_rows",
    },
    {
        "id": "A06",
        "title": "Category Name Normalizer with Typo Map",
        "description": (
            "Given a list of category strings and a mapping dict (e.g. 'Dog Food' -> 'Pet Food', 'dog food' -> 'Pet Food'), "
            "return a list of normalized names. Apply case-insensitive lookup; unmapped values returned as-is or default."
        ),
        "core_concepts": ["Dictionary lookup", "Case normalization", "Default handling"],
        "why_chewy": "Product catalog and search; unifying category names from multiple sources.",
        "interviewer_evaluates": "Efficient lookup; handling missing keys and case.",
        "common_mistakes": "Case-sensitive match only; mutating original list.",
        "dataset_required": "category_typos",
    },
    {
        "id": "A07",
        "title": "Semicolon-Delimited Parser with Quoted Fields",
        "description": (
            "Parse a string where fields are separated by semicolons; a field may be quoted and contain semicolons. "
            "Return a list of unquoted, unescaped field values. (Similar to CSV with ; delimiter.)"
        ),
        "core_concepts": ["Stateful parsing or regex", "Quote handling", "Escape sequences"],
        "why_chewy": "European-style CSVs and vendor feeds that use ; as separator.",
        "interviewer_evaluates": "Correct handling of quoted semicolons and escaped quotes.",
        "common_mistakes": "Naive split(';') breaking on inner semicolons; not unescaping.",
        "dataset_required": "semicolon_delimited",
    },
    {
        "id": "A08",
        "title": "Extract All Numbers from String",
        "description": (
            "Given a string that may contain integers and decimals (e.g. prices, IDs), extract all numbers "
            "and return as a list of floats (or ints when no decimal). Ignore currency symbols and commas as thousands."
        ),
        "core_concepts": ["Regex (re.findall)", "Type conversion", "Edge cases (1.2.3 vs 1.2)"],
        "why_chewy": "Scraping or parsing order/price text from mixed-format logs or docs.",
        "interviewer_evaluates": "Handling 1,234.56 vs 1.234 (locale); avoiding over-matching.",
        "common_mistakes": "Matching substrings of numbers; wrong locale handling.",
        "dataset_required": "text_with_numbers",
    },
    {
        "id": "A09",
        "title": "Semver Version String Validator and Parser",
        "description": (
            "Given a list of version strings (e.g. major.minor.patch), return a list of tuples (major, minor, patch) "
            "as integers for valid entries, and None for invalid. Define valid: 1-3 numeric segments, non-negative."
        ),
        "core_concepts": ["String split", "Type conversion", "Validation", "Structured return"],
        "why_chewy": "Version checks in dependency or API compatibility logic.",
        "interviewer_evaluates": "Clear validity rules; handling 1.0 vs 1.0.0.",
        "common_mistakes": "Allowing negative numbers; not handling missing segments.",
        "dataset_required": "version_strings",
    },
    {
        "id": "A10",
        "title": "Key=Value Log Parser with Quoted Values",
        "description": (
            "Parse a log line with key=value pairs where values may be quoted (and contain = or spaces). "
            "Return a dict. Example: user_id=1001 action=\"click item\" product_id=302."
        ),
        "core_concepts": ["Stateful parsing", "Quote awareness", "Dictionary building"],
        "why_chewy": "Structured logging and log aggregation; extracting event attributes.",
        "interviewer_evaluates": "Handling quoted values that contain = or spaces.",
        "common_mistakes": "Splitting on = only; not handling escaped quotes inside values.",
        "dataset_required": "log_lines_key_value",
    },
    {
        "id": "A11",
        "title": "Deduplicate Rows by Key Column",
        "description": (
            "Given a list of delimited lines (e.g. pipe-delimited) and the 0-based index of the 'key' column, "
            "return a list of lines keeping only the first occurrence of each key. Preserve header if present."
        ),
        "core_concepts": ["Set or dict for seen keys", "Split and join", "Order preservation"],
        "why_chewy": "Deduplicating feed files or exports before load.",
        "interviewer_evaluates": "Correct column index handling; header vs data row logic.",
        "common_mistakes": "Keeping last instead of first; not preserving header.",
        "dataset_required": "delimited_lines_key_column",
    },
    {
        "id": "A12",
        "title": "Boolean-Like String Normalizer",
        "description": (
            "Given a list of strings (yes/no, true/false, 1/0, on/off, mixed case), return a list of Python booleans. "
            "Unknown values: return None or raise; define the mapping clearly."
        ),
        "core_concepts": ["Dictionary mapping", "Case normalization", "Default/unknown handling"],
        "why_chewy": "Normalizing config and feature flags from various sources.",
        "interviewer_evaluates": "Explicit mapping; handling unknown without crashing.",
        "common_mistakes": "Only handling one variant; case-sensitive comparison.",
        "dataset_required": "boolean_like_strings",
    },
    {
        "id": "A13",
        "title": "Simple Table String to List of Dicts",
        "description": (
            "Given a string with a header row and data rows (comma or tab separated), parse into a list of dicts "
            "where each dict has header values as keys. Strip keys and values; handle empty cells."
        ),
        "core_concepts": ["Split lines and fields", "Zip with header", "Dictionary per row"],
        "why_chewy": "Quick parsing of small CSV-like payloads without pandas.",
        "interviewer_evaluates": "Handling different delimiters; consistent key names.",
        "common_mistakes": "Not stripping; wrong handling of empty last field.",
        "dataset_required": "simple_table_string",
    },
    {
        "id": "A14",
        "title": "Extract Date from Free-Text String",
        "description": (
            "Given a string that may contain a date (e.g. 'Order placed on 2024-01-15' or 'Shipped 2024-02-20'), "
            "extract the first date in YYYY-MM-DD form and return it as a string or (y, m, d). Return None if none found."
        ),
        "core_concepts": ["Regex for date pattern", "Validation (month/day ranges optional)", "String extraction"],
        "why_chewy": "Parsing order and shipping notes; extracting dates from unstructured text.",
        "interviewer_evaluates": "Robust pattern; not matching invalid dates (e.g. 2024-13-01).",
        "common_mistakes": "Matching partial numbers (e.g. 12345); no validation.",
        "dataset_required": "free_text_with_dates",
    },
]


# ---------------------------------------------------------------------------
# Solutions
# ---------------------------------------------------------------------------
# Pattern: one function per question, named solution_<id> (e.g. solution_A01).
# Signature should match the problem (e.g. accept the same inputs as DATASETS["<name>"]["sample"]).
# Use get_dataset_spec("<dataset_required>")["sample"] to get sample inputs for testing.
# Add your solutions below; this file stays runnable so you can test with:
#   python 02_questions_data_parsing_cleaning.py
# ---------------------------------------------------------------------------


def solution_A01(env_content: Union[str, List[str]]) -> Dict[str, str]:
    """
    Env-File Parser (A01).
    Parse KEY=value lines; strip keys/values; ignore blank lines and lines starting with #.
    """
    if isinstance(env_content, str):
        lines = env_content.strip().split("\n")
    else:
        lines = env_content
    result: Dict[str, str] = {}
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        result[key.strip()] = value.strip()
    return result


# Add more solutions as solution_A02, solution_A03, ... using the same pattern.


def get_all_questions() -> List[Dict[str, Any]]:
    return list(QUESTIONS)


def get_dataset_spec(name: str) -> Optional[Dict[str, Any]]:
    return DATASETS.get(name)


# ---------------------------------------------------------------------------
# Run example (use sample from DATASETS for the question's dataset_required)
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    sample = DATASETS["env_file"]["sample"][0]
    out = solution_A01(sample)
    print("A01 Env-File Parser — sample input (first line):", repr(sample.split("\n")[0]))
    print("A01 output:", out)
