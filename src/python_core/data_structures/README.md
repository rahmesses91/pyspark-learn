# Python Data Structures

This directory contains comprehensive learning materials for Python's core data structures, with examples focused on Data Engineering use cases.

## Directory Structure

```
data_structures/
├── README.md           # This file - Overview and navigation
├── strings/            # String manipulation and methods
├── lists/              # List operations, filter(), comprehensions
├── tuples/             # Tuple methods and use cases
├── dictionaries/       # Dictionary operations and patterns
├── sets/               # Set operations for data engineering
└── collections/        # Advanced collections module
```

## Quick Navigation

| Directory | Topics | Key Use Cases |
|-----------|--------|---------------|
| [strings/](./strings/) | `strip()`, `split()`, `join()`, validation | Data cleaning, parsing, normalization |
| [lists/](./lists/) | `filter()`, lambda, comprehensions | ETL filtering, transformation |
| [tuples/](./tuples/) | Immutability, unpacking, dict keys | Database rows, composite keys |
| [dictionaries/](./dictionaries/) | `get()`, `update()`, comprehensions | Lookup tables, JSON processing |
| [sets/](./sets/) | Union, intersection, difference | Deduplication, reconciliation |
| [collections/](./collections/) | Counter, defaultdict, deque, namedtuple | Log analysis, grouping, queues |

## Learning Path

### Beginner
1. **Strings** - Start with data cleaning basics
2. **Lists** - Learn filtering and transformation
3. **Dictionaries** - Master key-value operations

### Intermediate
4. **Tuples** - Understand immutability and composite keys
5. **Sets** - Learn set operations for data quality
6. **List Comprehension** - Write Pythonic transformations

### Advanced
7. **Collections Module** - Use specialized containers

## Data Structure Selection Guide

| Need | Use | Why |
|------|-----|-----|
| Ordered, mutable sequence | `list` | Flexible, supports all operations |
| Ordered, immutable sequence | `tuple` | Data integrity, hashable |
| Key-value mapping | `dict` | O(1) lookup by key |
| Unique values only | `set` | Auto-deduplication, O(1) membership |
| Count occurrences | `Counter` | Built-in counting methods |
| Group by key | `defaultdict(list)` | Auto-creates empty lists |
| Named record fields | `namedtuple` | Self-documenting, lightweight |
| FIFO queue | `deque` | O(1) at both ends |

## Common Data Engineering Patterns

### 1. ETL Filtering
```python
# Filter valid records
valid = [r for r in records if r["status"] == "active"]
# or
valid = list(filter(lambda r: r["status"] == "active", records))
```

### 2. Deduplication
```python
# Remove duplicates (order not preserved)
unique = list(set(items))

# Remove duplicates (order preserved)
seen = set()
unique = [x for x in items if not (x in seen or seen.add(x))]
```

### 3. Lookup Tables
```python
# Build lookup by ID
lookup = {record["id"]: record for record in records}
# Fast access
customer = lookup.get("C001")
```

### 4. Grouping
```python
from collections import defaultdict
groups = defaultdict(list)
for record in records:
    groups[record["category"]].append(record)
```

### 5. Data Reconciliation
```python
source_ids = set(s["id"] for s in source)
target_ids = set(t["id"] for t in target)
missing = source_ids - target_ids
extra = target_ids - source_ids
```

### 6. Frequency Analysis
```python
from collections import Counter
status_counts = Counter(r["status"] for r in records)
top_3 = status_counts.most_common(3)
```

## Performance Considerations

| Operation | list | dict | set |
|-----------|------|------|-----|
| Lookup by index | O(1) | N/A | N/A |
| Lookup by key/value | O(n) | O(1) | O(1) |
| Insert | O(1) append | O(1) | O(1) |
| Delete by value | O(n) | O(1) | O(1) |

**Tip**: For large datasets with frequent lookups, convert lists to sets or dicts.

## Notebook Format

Each directory contains Jupyter notebooks (`.ipynb`) with:
- Conceptual explanations with syntax diagrams
- Practical Data Engineering examples
- Common patterns and best practices
- Quick reference tables

All notebooks can be run interactively in JupyterLab.
