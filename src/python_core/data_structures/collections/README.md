# Python Collections Module

This directory contains learning materials for Python's `collections` module.

## Contents

| File | Description |
|------|-------------|
| `collections_module.ipynb` | Comprehensive notebook covering all major collection types |

## Topics Covered

### 1. Counter
**Purpose**: Count hashable objects

**Key Methods**:
- `most_common(n)` - Get n most frequent elements
- `elements()` - Iterator over elements
- `update()` - Add counts
- `subtract()` - Subtract counts
- Arithmetic: `+`, `-`, `&`, `|`

**Use Cases**: Log analysis, frequency distribution, data profiling

### 2. defaultdict
**Purpose**: Dict with automatic default values for missing keys

**Common Factories**:
- `defaultdict(list)` - Default empty list
- `defaultdict(int)` - Default 0
- `defaultdict(set)` - Default empty set
- `defaultdict(lambda: custom)` - Custom default

**Use Cases**: Grouping records, aggregation, avoiding KeyError

### 3. deque
**Purpose**: Double-ended queue with O(1) operations at both ends

**Key Methods**:
- `append()`, `appendleft()` - Add to ends
- `pop()`, `popleft()` - Remove from ends
- `rotate(n)` - Rotate elements
- `maxlen` - Fixed-size buffer

**Use Cases**: Queues, stacks, sliding windows, rolling calculations

### 4. namedtuple
**Purpose**: Tuple with named fields

**Key Methods**:
- `_make()` - Create from iterable
- `_asdict()` - Convert to dict
- `_replace()` - Create copy with changes
- `_fields` - Get field names

**Use Cases**: Database records, config objects, multiple return values

### 5. OrderedDict
**Purpose**: Dict with order-aware methods

**Unique Features**:
- `move_to_end()` - Move key to end/beginning
- `popitem(last=True/False)` - Pop from either end
- Equality considers order

### 6. ChainMap
**Purpose**: Combine multiple dicts for lookup

**Use Cases**: Layered configuration (env > user > defaults)

## Collection Type Comparison

| Type | Purpose | Key Benefit |
|------|---------|-------------|
| `Counter` | Count items | Built-in counting methods |
| `defaultdict` | Auto-default dict | No KeyError, cleaner code |
| `deque` | Double-ended queue | O(1) at both ends |
| `namedtuple` | Named tuple fields | Readable field access |
| `OrderedDict` | Order-aware dict | `move_to_end()`, order equality |
| `ChainMap` | Combine dicts | Layered lookups |

## Data Engineering Use Cases

- **Counter**: Log level analysis, error counting, value distributions
- **defaultdict**: Grouping records by key, building aggregations
- **deque**: Implementing queues, rolling averages, recent items cache
- **namedtuple**: Representing database rows, ETL record types
- **ChainMap**: Configuration with defaults and overrides

## Quick Examples

```python
from collections import Counter, defaultdict, deque, namedtuple, ChainMap

# Counter - Log analysis
logs = ["ERROR", "INFO", "ERROR", "WARNING", "INFO"]
counts = Counter(logs)
print(counts.most_common(2))  # [("INFO", 2), ("ERROR", 2)]

# defaultdict - Grouping
orders = [{"customer": "C1", "item": "A"}, {"customer": "C1", "item": "B"}]
by_customer = defaultdict(list)
for o in orders:
    by_customer[o["customer"]].append(o["item"])
# {"C1": ["A", "B"]}

# deque - Rolling average
window = deque(maxlen=3)
for price in [100, 102, 104, 103]:
    window.append(price)
    avg = sum(window) / len(window)

# namedtuple - Database records
Record = namedtuple("Record", ["id", "name", "email"])
r = Record("C001", "John", "john@example.com")
print(r.name)  # "John"

# ChainMap - Layered config
defaults = {"host": "localhost", "port": 5432}
overrides = {"host": "production.server.com"}
config = ChainMap(overrides, defaults)
print(config["host"])  # "production.server.com"
print(config["port"])  # 5432
```

## When to Use What

| Scenario | Use |
|----------|-----|
| Count occurrences | `Counter` |
| Group items by key | `defaultdict(list)` |
| Sum values by key | `defaultdict(int)` or `Counter` |
| FIFO queue | `deque` with `append()` and `popleft()` |
| LIFO stack | `deque` with `append()` and `pop()` |
| Keep last N items | `deque(maxlen=N)` |
| Named record fields | `namedtuple` |
| Config with defaults | `ChainMap` |

## Related Topics

- Built-in `dict`, `list`, `tuple`, `set`
- `dataclasses` module (Python 3.7+) for more complex records
- `heapq` module for priority queues
- `itertools` for advanced iteration
