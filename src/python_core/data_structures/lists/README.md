# Python Lists

This directory contains learning materials for Python list operations and techniques.

## Contents

| File | Description |
|------|-------------|
| `list_builtin_functions.ipynb` | Built-in functions for lists: `filter()`, `map()`, lambda |
| `list_comprehension.ipynb` | List comprehension patterns and problem-solving |

## Topics Covered

### Built-in Functions (`list_builtin_functions.ipynb`)

#### 1. `filter()` Function
- Filtering data records based on conditions
- Using regular functions vs lambda
- Data quality checks in ETL pipelines

#### 2. Lambda Functions
- Anonymous function syntax
- When to use lambda vs regular functions
- Combining lambda with `filter()`, `map()`, `sorted()`

#### 3. Best Practices
- `filter()` vs list comprehension comparison
- Chaining filters for data pipelines
- Memory efficiency considerations

### List Comprehension (`list_comprehension.ipynb`)

#### 1. Basic Syntax
- Transformation patterns: `[expr for item in iterable]`
- Filtering: `[expr for item in iterable if condition]`
- If-else expressions: `[a if cond else b for x in iter]`

#### 2. Nested Comprehensions
- Flattening 2D lists
- Creating matrices
- Matrix transposition

#### 3. Problem-Solving Examples
- Two Sum pairs
- FizzBuzz
- Remove duplicates preserving order
- Group anagrams
- Pascal's triangle
- Rotate array
- Find missing numbers
- And more...

## Data Engineering Use Cases

- **ETL Filtering**: Remove invalid/null records from datasets
- **Data Transformation**: Transform records in bulk
- **Deduplication**: Remove duplicate entries
- **Data Quality**: Validate records against business rules
- **Aggregation**: Group and process data efficiently

## Quick Examples

```python
# Filter valid transactions
transactions = [{"amount": 100}, {"amount": None}, {"amount": 200}]
valid = list(filter(lambda x: x["amount"] is not None, transactions))

# Using lambda with filter
high_value = list(filter(lambda x: x["amount"] > 150, valid))

# List comprehension - same result, different style
valid_comp = [t for t in transactions if t["amount"] is not None]

# Transform with comprehension
doubled = [t["amount"] * 2 for t in valid]

# Filter and transform in one line
high_doubled = [t["amount"] * 2 for t in transactions 
                if t["amount"] is not None and t["amount"] > 150]
```

## When to Use What

| Use Case | Recommended Approach |
|----------|---------------------|
| Simple filtering | List comprehension |
| Complex, reusable filter logic | `filter()` with named function |
| Quick inline filtering | `filter()` with lambda |
| Transform + filter | List comprehension |
| Memory-efficient (large data) | `filter()` (returns iterator) |

## Related Topics

- `map()` function for transformations
- `reduce()` from `functools` for aggregations
- Generator expressions for memory efficiency
- `itertools` module for advanced iteration
