"""
String Methods for Data Engineering
====================================
A comprehensive reference of Python string methods organized by category.
Focus: Data parsing, cleaning, and manipulation for data engineers.

Categories:
    A. Cleaning & Normalization
    B. Case Transformation
    C. Splitting & Joining
    D. Search & Find
    E. Replacement & Substitution
    F. Validation & Checking
    G. Formatting & Alignment
    H. Encoding & Decoding
"""

# =============================================================================
# SECTION A: CLEANING & NORMALIZATION
# =============================================================================

def demo_strip():
    """
    strip([chars]) - Removes whitespace (or specified chars) from both ends.
    Time Complexity: O(n) where n is string length
    Use Case: Cleaning raw data with leading/trailing spaces
    """
    raw_data = "   John Doe   "
    cleaned = raw_data.strip()
    print(f"strip(): '{raw_data}' -> '{cleaned}'")
    
    # Remove specific characters
    data_with_brackets = "###ID_001###"
    cleaned_chars = data_with_brackets.strip('#')
    print(f"strip('#'): '{data_with_brackets}' -> '{cleaned_chars}'")


def demo_lstrip():
    """
    lstrip([chars]) - Removes whitespace (or specified chars) from left side only.
    Time Complexity: O(n)
    Use Case: Removing leading zeros, prefixes
    """
    padded_id = "000042"
    cleaned = padded_id.lstrip('0')
    print(f"lstrip('0'): '{padded_id}' -> '{cleaned}'")


def demo_rstrip():
    """
    rstrip([chars]) - Removes whitespace (or specified chars) from right side only.
    Time Complexity: O(n)
    Use Case: Removing trailing newlines, suffixes from file data
    """
    file_line = "data_value\n\n"
    cleaned = file_line.rstrip('\n')
    print(f"rstrip('\\n'): '{repr(file_line)}' -> '{repr(cleaned)}'")


def demo_replace():
    """
    replace(old, new[, count]) - Replaces occurrences of substring.
    Time Complexity: O(n*m) where m is occurrences
    Use Case: Data standardization, fixing inconsistent formats
    """
    phone = "123-456-7890"
    cleaned = phone.replace("-", "")
    print(f"replace('-', ''): '{phone}' -> '{cleaned}'")
    
    # Replace with count limit
    text = "a,b,c,d,e"
    partial = text.replace(",", "|", 2)
    print(f"replace(',', '|', 2): '{text}' -> '{partial}'")


def demo_removeprefix():
    """
    removeprefix(prefix) - Removes prefix if present (Python 3.9+).
    Time Complexity: O(n)
    Use Case: Removing consistent prefixes from IDs, codes
    """
    order_id = "ORD_12345"
    cleaned = order_id.removeprefix("ORD_")
    print(f"removeprefix('ORD_'): '{order_id}' -> '{cleaned}'")


def demo_removesuffix():
    """
    removesuffix(suffix) - Removes suffix if present (Python 3.9+).
    Time Complexity: O(n)
    Use Case: Removing file extensions, suffixes from data
    """
    filename = "report_2024.csv"
    cleaned = filename.removesuffix(".csv")
    print(f"removesuffix('.csv'): '{filename}' -> '{cleaned}'")


# =============================================================================
# SECTION B: CASE TRANSFORMATION
# =============================================================================

def demo_lower():
    """
    lower() - Converts all characters to lowercase.
    Time Complexity: O(n)
    Use Case: Normalizing data for case-insensitive comparisons
    """
    email = "John.Doe@Company.COM"
    normalized = email.lower()
    print(f"lower(): '{email}' -> '{normalized}'")


def demo_upper():
    """
    upper() - Converts all characters to uppercase.
    Time Complexity: O(n)
    Use Case: Standardizing codes, IDs
    """
    code = "abc123"
    standardized = code.upper()
    print(f"upper(): '{code}' -> '{standardized}'")


def demo_title():
    """
    title() - Capitalizes first letter of each word.
    Time Complexity: O(n)
    Use Case: Formatting names, titles
    """
    name = "john doe"
    formatted = name.title()
    print(f"title(): '{name}' -> '{formatted}'")


def demo_capitalize():
    """
    capitalize() - Capitalizes only the first character.
    Time Complexity: O(n)
    Use Case: Sentence formatting
    """
    sentence = "hello world"
    formatted = sentence.capitalize()
    print(f"capitalize(): '{sentence}' -> '{formatted}'")


def demo_swapcase():
    """
    swapcase() - Swaps uppercase to lowercase and vice versa.
    Time Complexity: O(n)
    Use Case: Data transformation, testing
    """
    text = "Hello World"
    swapped = text.swapcase()
    print(f"swapcase(): '{text}' -> '{swapped}'")


def demo_casefold():
    """
    casefold() - Aggressive lowercase for case-insensitive comparisons.
    Time Complexity: O(n)
    Use Case: Handling international characters in comparisons
    """
    german = "Straße"
    folded = german.casefold()
    print(f"casefold(): '{german}' -> '{folded}'")


# =============================================================================
# SECTION C: SPLITTING & JOINING
# =============================================================================

def demo_split():
    """
    split([sep[, maxsplit]]) - Splits string into list.
    Time Complexity: O(n)
    Use Case: Parsing CSV-like data, extracting fields
    """
    csv_row = "John,Doe,30,Engineer"
    fields = csv_row.split(",")
    print(f"split(','): '{csv_row}' -> {fields}")
    
    # With maxsplit
    log_line = "2024-01-15 10:30:45 ERROR Something went wrong"
    parts = log_line.split(" ", 2)
    print(f"split(' ', 2): -> {parts}")


def demo_rsplit():
    """
    rsplit([sep[, maxsplit]]) - Splits from right side.
    Time Complexity: O(n)
    Use Case: Extracting last N fields, parsing paths
    """
    path = "/home/user/data/file.csv"
    parts = path.rsplit("/", 1)
    print(f"rsplit('/', 1): '{path}' -> {parts}")


def demo_splitlines():
    """
    splitlines([keepends]) - Splits on line boundaries.
    Time Complexity: O(n)
    Use Case: Processing multi-line text data
    """
    multi_line = "Line1\nLine2\r\nLine3"
    lines = multi_line.splitlines()
    print(f"splitlines(): -> {lines}")


def demo_join():
    """
    sep.join(iterable) - Joins elements with separator.
    Time Complexity: O(n) where n is total characters
    Use Case: Building delimited strings, creating paths
    """
    fields = ["John", "Doe", "30"]
    csv_row = ",".join(fields)
    print(f"','.join(): {fields} -> '{csv_row}'")
    
    path_parts = ["home", "user", "data"]
    path = "/".join(path_parts)
    print(f"'/'.join(): {path_parts} -> '{path}'")


def demo_partition():
    """
    partition(sep) - Splits into 3 parts: before, sep, after (first occurrence).
    Time Complexity: O(n)
    Use Case: Extracting key-value pairs, splitting on first delimiter
    """
    key_value = "name=John Doe"
    key, sep, value = key_value.partition("=")
    print(f"partition('='): '{key_value}' -> ('{key}', '{sep}', '{value}')")


def demo_rpartition():
    """
    rpartition(sep) - Splits into 3 parts from right (last occurrence).
    Time Complexity: O(n)
    Use Case: Extracting file extension, splitting on last delimiter
    """
    filename = "archive.tar.gz"
    name, sep, ext = filename.rpartition(".")
    print(f"rpartition('.'): '{filename}' -> ('{name}', '{sep}', '{ext}')")


# =============================================================================
# SECTION D: SEARCH & FIND
# =============================================================================

def demo_find():
    """
    find(sub[, start[, end]]) - Returns index of first occurrence, -1 if not found.
    Time Complexity: O(n*m) where m is substring length
    Use Case: Locating substrings, checking presence
    """
    log = "ERROR: Connection failed at 10:30"
    pos = log.find("ERROR")
    print(f"find('ERROR'): '{log}' -> index {pos}")
    
    not_found = log.find("WARNING")
    print(f"find('WARNING'): -> {not_found}")


def demo_rfind():
    """
    rfind(sub[, start[, end]]) - Returns index of last occurrence.
    Time Complexity: O(n*m)
    Use Case: Finding last occurrence of delimiter
    """
    path = "/home/user/data/file.csv"
    last_slash = path.rfind("/")
    print(f"rfind('/'): '{path}' -> index {last_slash}")


def demo_index():
    """
    index(sub[, start[, end]]) - Like find() but raises ValueError if not found.
    Time Complexity: O(n*m)
    Use Case: When substring must exist (fail-fast approach)
    """
    text = "Hello World"
    try:
        pos = text.index("World")
        print(f"index('World'): '{text}' -> index {pos}")
    except ValueError as e:
        print(f"ValueError: {e}")


def demo_rindex():
    """
    rindex(sub[, start[, end]]) - Like rfind() but raises ValueError if not found.
    Time Complexity: O(n*m)
    """
    text = "one.two.three"
    pos = text.rindex(".")
    print(f"rindex('.'): '{text}' -> index {pos}")


def demo_count():
    """
    count(sub[, start[, end]]) - Counts non-overlapping occurrences.
    Time Complexity: O(n*m)
    Use Case: Counting delimiters, validating data format
    """
    email = "john.doe@company.com"
    at_count = email.count("@")
    dot_count = email.count(".")
    print(f"count('@'): '{email}' -> {at_count}")
    print(f"count('.'): '{email}' -> {dot_count}")


# =============================================================================
# SECTION E: REPLACEMENT & SUBSTITUTION
# =============================================================================

def demo_translate():
    """
    translate(table) - Replaces characters using translation table.
    Time Complexity: O(n)
    Use Case: Bulk character replacement, removing multiple characters
    """
    # Create translation table
    table = str.maketrans("aeiou", "12345")
    text = "hello world"
    translated = text.translate(table)
    print(f"translate(): '{text}' -> '{translated}'")
    
    # Remove characters
    remove_table = str.maketrans("", "", "!@#$%")
    dirty_data = "Price: $100!!"
    cleaned = dirty_data.translate(remove_table)
    print(f"translate(remove): '{dirty_data}' -> '{cleaned}'")


def demo_expandtabs():
    """
    expandtabs([tabsize]) - Replaces tabs with spaces.
    Time Complexity: O(n)
    Use Case: Normalizing whitespace in data
    """
    tsv_line = "Name\tAge\tCity"
    expanded = tsv_line.expandtabs(4)
    print(f"expandtabs(4): '{repr(tsv_line)}' -> '{expanded}'")


# =============================================================================
# SECTION F: VALIDATION & CHECKING
# =============================================================================

def demo_startswith():
    """
    startswith(prefix[, start[, end]]) - Checks if string starts with prefix.
    Time Complexity: O(k) where k is prefix length
    Use Case: Filtering data by prefix, validating formats
    """
    order_id = "ORD_12345"
    is_order = order_id.startswith("ORD_")
    print(f"startswith('ORD_'): '{order_id}' -> {is_order}")
    
    # Multiple prefixes
    code = "USD_100"
    is_currency = code.startswith(("USD_", "EUR_", "GBP_"))
    print(f"startswith(('USD_', 'EUR_', 'GBP_')): '{code}' -> {is_currency}")


def demo_endswith():
    """
    endswith(suffix[, start[, end]]) - Checks if string ends with suffix.
    Time Complexity: O(k) where k is suffix length
    Use Case: Checking file extensions, validating formats
    """
    filename = "data.csv"
    is_csv = filename.endswith(".csv")
    print(f"endswith('.csv'): '{filename}' -> {is_csv}")
    
    # Multiple suffixes
    is_data_file = filename.endswith((".csv", ".json", ".parquet"))
    print(f"endswith(('.csv', '.json', '.parquet')): -> {is_data_file}")


def demo_isalpha():
    """
    isalpha() - True if all characters are alphabetic.
    Time Complexity: O(n)
    Use Case: Validating name fields
    """
    name = "John"
    print(f"isalpha(): '{name}' -> {name.isalpha()}")
    name_with_space = "John Doe"
    print(f"isalpha(): '{name_with_space}' -> {name_with_space.isalpha()}")


def demo_isdigit():
    """
    isdigit() - True if all characters are digits.
    Time Complexity: O(n)
    Use Case: Validating numeric IDs, phone numbers
    """
    phone = "1234567890"
    print(f"isdigit(): '{phone}' -> {phone.isdigit()}")
    phone_formatted = "123-456-7890"
    print(f"isdigit(): '{phone_formatted}' -> {phone_formatted.isdigit()}")


def demo_isnumeric():
    """
    isnumeric() - True if all characters are numeric (includes fractions, etc.).
    Time Complexity: O(n)
    Use Case: Broader numeric validation
    """
    num = "12345"
    fraction = "½"
    print(f"isnumeric(): '{num}' -> {num.isnumeric()}")
    print(f"isnumeric(): '{fraction}' -> {fraction.isnumeric()}")


def demo_isdecimal():
    """
    isdecimal() - True if all characters are decimal digits.
    Time Complexity: O(n)
    Use Case: Strict numeric validation
    """
    num = "12345"
    print(f"isdecimal(): '{num}' -> {num.isdecimal()}")


def demo_isalnum():
    """
    isalnum() - True if all characters are alphanumeric.
    Time Complexity: O(n)
    Use Case: Validating IDs, usernames
    """
    user_id = "user123"
    print(f"isalnum(): '{user_id}' -> {user_id.isalnum()}")
    email = "user@test.com"
    print(f"isalnum(): '{email}' -> {email.isalnum()}")


def demo_isspace():
    """
    isspace() - True if all characters are whitespace.
    Time Complexity: O(n)
    Use Case: Detecting empty/whitespace-only fields
    """
    spaces = "   "
    print(f"isspace(): '{repr(spaces)}' -> {spaces.isspace()}")
    text = " hi "
    print(f"isspace(): '{text}' -> {text.isspace()}")


def demo_islower():
    """
    islower() - True if all cased characters are lowercase.
    Time Complexity: O(n)
    Use Case: Validating normalized data
    """
    lower = "hello"
    mixed = "Hello"
    print(f"islower(): '{lower}' -> {lower.islower()}")
    print(f"islower(): '{mixed}' -> {mixed.islower()}")


def demo_isupper():
    """
    isupper() - True if all cased characters are uppercase.
    Time Complexity: O(n)
    Use Case: Validating codes, constants
    """
    upper = "HELLO"
    mixed = "Hello"
    print(f"isupper(): '{upper}' -> {upper.isupper()}")
    print(f"isupper(): '{mixed}' -> {mixed.isupper()}")


def demo_istitle():
    """
    istitle() - True if string is titlecased.
    Time Complexity: O(n)
    Use Case: Validating proper names
    """
    title = "John Doe"
    not_title = "john doe"
    print(f"istitle(): '{title}' -> {title.istitle()}")
    print(f"istitle(): '{not_title}' -> {not_title.istitle()}")


def demo_isidentifier():
    """
    isidentifier() - True if valid Python identifier.
    Time Complexity: O(n)
    Use Case: Validating column names, variable names
    """
    valid = "column_name"
    invalid = "123column"
    print(f"isidentifier(): '{valid}' -> {valid.isidentifier()}")
    print(f"isidentifier(): '{invalid}' -> {invalid.isidentifier()}")


def demo_isprintable():
    """
    isprintable() - True if all characters are printable.
    Time Complexity: O(n)
    Use Case: Detecting control characters in data
    """
    printable = "Hello World!"
    with_tab = "Hello\tWorld"
    print(f"isprintable(): '{printable}' -> {printable.isprintable()}")
    print(f"isprintable(): '{repr(with_tab)}' -> {with_tab.isprintable()}")


def demo_isascii():
    """
    isascii() - True if all characters are ASCII (Python 3.7+).
    Time Complexity: O(n)
    Use Case: Detecting non-ASCII characters
    """
    ascii_text = "Hello"
    unicode_text = "Héllo"
    print(f"isascii(): '{ascii_text}' -> {ascii_text.isascii()}")
    print(f"isascii(): '{unicode_text}' -> {unicode_text.isascii()}")


# =============================================================================
# SECTION G: FORMATTING & ALIGNMENT
# =============================================================================

def demo_format():
    """
    format(*args, **kwargs) - Formats string with placeholders.
    Time Complexity: O(n)
    Use Case: Building dynamic strings, SQL queries (carefully!)
    """
    template = "Name: {name}, Age: {age}"
    formatted = template.format(name="John", age=30)
    print(f"format(): '{template}' -> '{formatted}'")
    
    # Positional
    template2 = "Value: {0}, Count: {1}"
    formatted2 = template2.format(100, 5)
    print(f"format(): '{template2}' -> '{formatted2}'")


def demo_format_map():
    """
    format_map(mapping) - Like format() but takes a mapping directly.
    Time Complexity: O(n)
    Use Case: Formatting with dictionaries
    """
    template = "Name: {name}, City: {city}"
    data = {"name": "John", "city": "NYC"}
    formatted = template.format_map(data)
    print(f"format_map(): -> '{formatted}'")


def demo_center():
    """
    center(width[, fillchar]) - Centers string with padding.
    Time Complexity: O(n)
    Use Case: Creating formatted reports
    """
    title = "Report"
    centered = title.center(20, "-")
    print(f"center(20, '-'): '{title}' -> '{centered}'")


def demo_ljust():
    """
    ljust(width[, fillchar]) - Left-justifies with padding.
    Time Complexity: O(n)
    Use Case: Creating fixed-width fields
    """
    name = "John"
    padded = name.ljust(10, ".")
    print(f"ljust(10, '.'): '{name}' -> '{padded}'")


def demo_rjust():
    """
    rjust(width[, fillchar]) - Right-justifies with padding.
    Time Complexity: O(n)
    Use Case: Right-aligning numbers, IDs
    """
    num = "42"
    padded = num.rjust(5, "0")
    print(f"rjust(5, '0'): '{num}' -> '{padded}'")


def demo_zfill():
    """
    zfill(width) - Pads with zeros on the left.
    Time Complexity: O(n)
    Use Case: Creating zero-padded IDs, numbers
    """
    order_num = "123"
    padded = order_num.zfill(8)
    print(f"zfill(8): '{order_num}' -> '{padded}'")
    
    # Handles negative numbers correctly
    negative = "-42"
    padded_neg = negative.zfill(5)
    print(f"zfill(5): '{negative}' -> '{padded_neg}'")


# =============================================================================
# SECTION H: ENCODING & DECODING
# =============================================================================

def demo_encode():
    """
    encode([encoding[, errors]]) - Encodes string to bytes.
    Time Complexity: O(n)
    Use Case: Preparing data for binary storage, network transmission
    """
    text = "Hello World"
    encoded = text.encode("utf-8")
    print(f"encode('utf-8'): '{text}' -> {encoded}")
    
    # With special characters
    unicode_text = "Café"
    encoded_unicode = unicode_text.encode("utf-8")
    print(f"encode('utf-8'): '{unicode_text}' -> {encoded_unicode}")


# =============================================================================
# DATA ENGINEERING UTILITY FUNCTIONS
# =============================================================================

def clean_whitespace(text: str) -> str:
    """
    Removes leading/trailing whitespace and normalizes internal spaces.
    Use Case: Cleaning messy data fields
    """
    return " ".join(text.split())


def extract_between(text: str, start: str, end: str) -> str:
    """
    Extracts substring between two delimiters.
    Use Case: Parsing structured text data
    """
    start_idx = text.find(start)
    if start_idx == -1:
        return ""
    start_idx += len(start)
    end_idx = text.find(end, start_idx)
    if end_idx == -1:
        return ""
    return text[start_idx:end_idx]


def normalize_phone(phone: str) -> str:
    """
    Normalizes phone number to digits only.
    Use Case: Standardizing phone number formats
    """
    return "".join(c for c in phone if c.isdigit())


def safe_split(text: str, delimiter: str, expected_fields: int) -> list:
    """
    Splits string and ensures expected number of fields.
    Use Case: Parsing fixed-format data safely
    """
    parts = text.split(delimiter)
    # Pad with empty strings if needed
    while len(parts) < expected_fields:
        parts.append("")
    return parts[:expected_fields]


def is_empty_or_whitespace(text: str) -> bool:
    """
    Checks if string is empty or contains only whitespace.
    Use Case: Validating required fields
    """
    return not text or text.isspace()


def truncate(text: str, max_length: int, suffix: str = "...") -> str:
    """
    Truncates text to max length with suffix.
    Use Case: Creating previews, limiting field length
    """
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix


# =============================================================================
# MAIN - RUN ALL DEMOS
# =============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("STRING METHODS FOR DATA ENGINEERING")
    print("=" * 60)
    
    sections = [
        ("SECTION A: CLEANING & NORMALIZATION", [
            demo_strip, demo_lstrip, demo_rstrip, demo_replace,
            demo_removeprefix, demo_removesuffix
        ]),
        ("SECTION B: CASE TRANSFORMATION", [
            demo_lower, demo_upper, demo_title, demo_capitalize,
            demo_swapcase, demo_casefold
        ]),
        ("SECTION C: SPLITTING & JOINING", [
            demo_split, demo_rsplit, demo_splitlines, demo_join,
            demo_partition, demo_rpartition
        ]),
        ("SECTION D: SEARCH & FIND", [
            demo_find, demo_rfind, demo_index, demo_rindex, demo_count
        ]),
        ("SECTION E: REPLACEMENT & SUBSTITUTION", [
            demo_translate, demo_expandtabs
        ]),
        ("SECTION F: VALIDATION & CHECKING", [
            demo_startswith, demo_endswith, demo_isalpha, demo_isdigit,
            demo_isnumeric, demo_isdecimal, demo_isalnum, demo_isspace,
            demo_islower, demo_isupper, demo_istitle, demo_isidentifier,
            demo_isprintable, demo_isascii
        ]),
        ("SECTION G: FORMATTING & ALIGNMENT", [
            demo_format, demo_format_map, demo_center, demo_ljust,
            demo_rjust, demo_zfill
        ]),
        ("SECTION H: ENCODING & DECODING", [
            demo_encode
        ]),
    ]
    
    for section_name, demos in sections:
        print(f"\n{section_name}")
        print("-" * 60)
        for demo in demos:
            demo()
            print()
    
    # Demo utility functions
    print("\nDATA ENGINEERING UTILITY FUNCTIONS")
    print("-" * 60)
    print(f"clean_whitespace('  hello   world  '): '{clean_whitespace('  hello   world  ')}'")
    print(f"extract_between('<tag>value</tag>', '<tag>', '</tag>'): '{extract_between('<tag>value</tag>', '<tag>', '</tag>')}'")
    print(f"normalize_phone('(123) 456-7890'): '{normalize_phone('(123) 456-7890')}'")
    print(f"safe_split('a,b', ',', 4): {safe_split('a,b', ',', 4)}")
    print(f"is_empty_or_whitespace('   '): {is_empty_or_whitespace('   ')}")
    print(f"truncate('Hello World', 8): '{truncate('Hello World', 8)}'")
