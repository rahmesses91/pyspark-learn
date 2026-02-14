# Python Dictionaries

This directory contains learning materials for Python dictionaries.

## Contents

| File | Description |
|------|-------------|
| `dict_methods.ipynb` | Comprehensive notebook covering dictionary operations and methods |

## Topics Covered

### 1. Creating Dictionaries
- Literal syntax: `{"key": "value"}`
- `dict()` constructor
- From list of tuples
- Dictionary comprehension
- `fromkeys()` for initialization

### 2. Accessing Values
- Direct access: `d[key]` (raises KeyError if missing)
- `get()` - Safe access with default value
- Chained `get()` for nested JSON data
- `setdefault()` - Get or set default

### 3. Modifying Dictionaries
- Adding/updating: `d[key] = value`
- `update()` - Merge another dict
- Merge operator `|` (Python 3.9+)
- `del`, `pop()`, `popitem()`, `clear()`

### 4. Iterating
- `keys()`, `values()`, `items()`
- Dictionary comprehension for transformation

### 5. Dictionary Comprehension
- Create lookup tables
- Filter by keys or values
- Transform records
- Swap keys and values

### 6. Membership & Copying
- `in` operator for key checking
- Shallow copy vs deep copy

## Key Properties

| Property | Description |
|----------|-------------|
| Key-Value Mapping | Associates keys with values |
| Keys must be hashable | Strings, numbers, tuples (not lists) |
| O(1) lookup | Constant-time access by key |
| Maintains order | Insertion order preserved (Python 3.7+) |

## Data Engineering Use Cases

- **Lookup Tables**: Fast key-based data retrieval
- **JSON Processing**: Native representation of JSON data
- **Configuration**: Store and manage settings
- **Caching/Memoization**: Store computed results
- **Record Representation**: Flexible data structure for records
- **Aggregation**: Group and sum by key
- **Data Transformation**: Field renaming, value mapping

## Quick Examples

```python
# Create lookup table from records
customers = [
    {"id": "C001", "name": "John"},
    {"id": "C002", "name": "Jane"},
]
lookup = {c["id"]: c for c in customers}
print(lookup["C001"])  # {"id": "C001", "name": "John"}

# Safe nested access
data = {"user": {"profile": {"age": 30}}}
age = data.get("user", {}).get("profile", {}).get("age", "Unknown")

# Aggregate by key
orders = [{"customer": "C001", "amount": 100}, {"customer": "C001", "amount": 50}]
totals = {}
for o in orders:
    totals[o["customer"]] = totals.get(o["customer"], 0) + o["amount"]

# Filter dict
data = {"a": 1, "b": 2, "c": 3}
filtered = {k: v for k, v in data.items() if v > 1}  # {"b": 2, "c": 3}

# Merge dicts (Python 3.9+)
defaults = {"host": "localhost", "port": 5432}
overrides = {"host": "production.server.com"}
config = defaults | overrides
```

## Common Patterns

| Pattern | Code |
|---------|------|
| Get with default | `d.get(key, default)` |
| Update multiple | `d.update(other_dict)` |
| Create lookup | `{item[key]: item for item in list}` |
| Aggregate | `d[k] = d.get(k, 0) + value` |
| Merge | `d1 \| d2` or `{**d1, **d2}` |

## Related Topics

- `defaultdict` from `collections` for automatic defaults
- `Counter` from `collections` for counting
- `ChainMap` from `collections` for layered configs
- JSON module for serialization
