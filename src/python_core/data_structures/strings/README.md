# Python Strings

This directory contains learning materials for Python string manipulation and methods.

## Contents

| File | Description |
|------|-------------|
| `string_methods.ipynb` | Comprehensive notebook covering all essential string methods |
| `string_methods.py` | Python script version of string methods |
| `challenges.py` | Practice challenges for string manipulation |

## Topics Covered

### 1. Cleaning & Normalization
- `strip()`, `lstrip()`, `rstrip()` - Remove whitespace/characters
- `replace()` - Replace substrings
- `removeprefix()`, `removesuffix()` - Remove exact prefix/suffix (Python 3.9+)

### 2. Case Transformation
- `lower()`, `upper()` - Convert case
- `title()`, `capitalize()` - Format proper names

### 3. Splitting & Joining
- `split()`, `rsplit()` - Break strings into lists
- `join()` - Combine list elements into string
- `partition()` - Split into three parts

### 4. Search & Find
- `find()`, `rfind()` - Locate substrings
- `count()` - Count occurrences

### 5. Validation & Checking
- `startswith()`, `endswith()` - Check prefix/suffix
- `isdigit()`, `isalpha()`, `isalnum()` - Character type checks
- `isspace()` - Check for whitespace

### 6. Formatting & Alignment
- `zfill()` - Zero-padding
- `ljust()`, `rjust()`, `center()` - Text alignment

## Data Engineering Use Cases

- **Data Cleaning**: Removing whitespace, standardizing formats
- **Parsing**: Breaking apart CSV rows, log lines, file paths
- **Validation**: Checking email formats, required field formats
- **Normalization**: Standardizing emails to lowercase, phone number formats
- **Building Outputs**: Constructing CSV rows, file paths, formatted reports

## Quick Examples

```python
# Clean raw data
raw = "   John Doe   "
clean = raw.strip()  # "John Doe"

# Parse CSV row
row = "John,Doe,30,Engineer"
fields = row.split(",")  # ["John", "Doe", "30", "Engineer"]

# Validate email
email = "user@domain.com"
is_valid = email.count("@") == 1  # True

# Standardize format
email = "John@Company.COM".lower()  # "john@company.com"
```

## Related Topics

- Regular expressions (`re` module) for complex pattern matching
- `textwrap` module for text formatting
- f-strings for string interpolation
