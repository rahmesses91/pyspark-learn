# Python Tuples

This directory contains learning materials for Python tuples.

## Contents

| File | Description |
|------|-------------|
| `tuple_methods.ipynb` | Comprehensive notebook covering tuple creation, methods, and use cases |

## Topics Covered

### 1. Creating Tuples
- Parentheses syntax: `(1, 2, 3)`
- Tuple packing: `1, 2, 3`
- `tuple()` constructor
- Single-element tuple gotcha: `(42,)` not `(42)`

### 2. Accessing Elements
- Indexing and slicing
- Tuple unpacking: `a, b, c = tuple`
- Extended unpacking with `*`: `first, *middle, last = tuple`
- Ignoring values with `_`

### 3. Tuple Methods
- `count()` - Count occurrences of a value
- `index()` - Find index of first occurrence

### 4. Immutability
- Cannot modify tuple elements
- Mutable objects inside tuples can be modified
- Creating new tuples via concatenation

### 5. Tuples as Dictionary Keys
- Composite/compound keys
- Fast lookups with tuple keys
- Lists cannot be dict keys (unhashable)

### 6. Tuples in Functions
- Returning multiple values
- Validation patterns: `(is_valid, error_message)`
- `*args` creates tuples

### 7. Tuple Operations
- Concatenation: `t1 + t2`
- Repetition: `t * n`
- Membership: `x in t`
- Comparison (element by element)

## Key Properties

| Property | Description |
|----------|-------------|
| Immutable | Cannot change after creation |
| Ordered | Maintains insertion order |
| Allows duplicates | Same value can appear multiple times |
| Hashable | Can be used as dict keys, set elements |
| Slightly faster | Less memory than lists |

## Data Engineering Use Cases

- **Database Rows**: Represent fixed-structure records
- **Composite Keys**: Multi-field lookups in dictionaries
- **Multiple Return Values**: Functions returning (status, result)
- **Immutable Configuration**: Settings that shouldn't change
- **Data Integrity**: Prevent accidental modification
- **Sorting**: Multi-field sort keys

## Quick Examples

```python
# Database-style row
row = ("C001", "John Doe", "john@example.com", 100.00)
customer_id, name, email, balance = row  # Unpacking

# Composite dictionary key
sales = {
    ("east", "laptop"): 150,
    ("west", "laptop"): 180,
}
print(sales[("east", "laptop")])  # 150

# Return multiple values
def validate(record):
    if "email" not in record:
        return False, "Missing email"
    return True, None

is_valid, error = validate({"name": "John"})

# Swap values
a, b = b, a  # Uses tuple packing/unpacking
```

## Tuple vs List: When to Use Which

| Use Tuple | Use List |
|-----------|----------|
| Data should not change | Data will be modified |
| Need hashable (dict key, set element) | Don't need hashable |
| Heterogeneous data (different types) | Homogeneous data (same type) |
| Fixed structure (like a record) | Variable length collection |
| Want to prevent accidental modification | Need append/remove/etc. |

## Related Topics

- `namedtuple` from `collections` for named fields
- `dataclasses` for more complex record types
- Dictionary composite keys
