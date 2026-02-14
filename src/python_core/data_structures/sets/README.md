# Python Sets

This directory contains learning materials for Python sets.

## Contents

| File | Description |
|------|-------------|
| `set_methods.ipynb` | Comprehensive notebook covering set operations and methods |

## Topics Covered

### 1. Creating Sets
- Curly braces: `{1, 2, 3}`
- `set()` constructor (required for empty set)
- From lists (automatic deduplication)

### 2. Adding & Removing Elements
- `add()` - Add single element
- `update()` - Add multiple elements
- `remove()` - Remove (raises KeyError if missing)
- `discard()` - Remove (safe, no error)
- `pop()` - Remove and return arbitrary element
- `clear()` - Remove all elements

### 3. Set Operations (Most Important!)
- **Union** (`|`): All elements from both sets
- **Intersection** (`&`): Common elements only
- **Difference** (`-`): Elements in first but not second
- **Symmetric Difference** (`^`): Elements in either but not both

### 4. Membership & Comparison
- `in` operator - O(1) fast lookup
- `issubset()` - Check if contained in another
- `issuperset()` - Check if contains another
- `isdisjoint()` - Check for no common elements

### 5. Frozen Sets
- Immutable version of sets
- Can be used as dictionary keys

## Key Properties

| Property | Description |
|----------|-------------|
| Unique elements | No duplicates allowed |
| Unordered | No index access |
| Mutable | Can add/remove elements |
| O(1) lookup | Fast membership testing |
| Elements must be hashable | Strings, numbers, tuples only |

## Data Engineering Use Cases

- **Deduplication**: Remove duplicate records
- **Membership Testing**: Fast O(1) value validation
- **Data Reconciliation**: Find missing/extra records between systems
- **Change Detection**: Identify added/removed items between snapshots
- **Data Quality**: Validate against allowed values
- **Partition Validation**: Ensure no overlap between data partitions

## Quick Examples

```python
# Deduplication
raw_ids = ["A001", "A002", "A001", "A003"]
unique_ids = set(raw_ids)  # {"A001", "A002", "A003"}

# Fast membership testing
valid_statuses = {"active", "pending", "completed"}
is_valid = "active" in valid_statuses  # O(1) lookup

# Find missing records after ETL
source = {"R001", "R002", "R003", "R004"}
target = {"R001", "R002", "R003"}
missing = source - target  # {"R004"}

# Find common customers across regions
east = {"C001", "C002", "C003"}
west = {"C002", "C003", "C004"}
both_regions = east & west  # {"C002", "C003"}

# Data quality report
all_discrepancies = source ^ target  # {"R004"}

# Validate required fields
required = {"id", "name", "email"}
record_fields = {"id", "name"}
missing_fields = required - record_fields  # {"email"}
```

## Set Operations Visual Guide

```
A = {1, 2, 3, 4}
B = {3, 4, 5, 6}

Union (A | B):                 {1, 2, 3, 4, 5, 6}  ← All elements
Intersection (A & B):          {3, 4}              ← Common only
Difference (A - B):            {1, 2}              ← In A, not B
Difference (B - A):            {5, 6}              ← In B, not A
Symmetric Difference (A ^ B):  {1, 2, 5, 6}        ← In either, not both
```

## Performance: Set vs List

| Operation | Set | List |
|-----------|-----|------|
| Lookup (`in`) | O(1) | O(n) |
| Add | O(1) | O(1) |
| Remove | O(1) | O(n) |

Sets can be 1000x+ faster for membership testing on large datasets.

## Related Topics

- `frozenset` for immutable sets
- `Counter` from `collections` for counting
- Set comprehension: `{x for x in iterable}`
