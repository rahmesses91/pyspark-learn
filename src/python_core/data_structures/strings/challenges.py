"""
String Methods Challenges - Data Engineering Practice
======================================================
Application-based challenges to practice string manipulation techniques.
"""

# =============================================================================
# CHALLENGE A1: Clean Customer Data Pipeline
# Section: Cleaning & Normalization
# Difficulty: Beginner
# =============================================================================

"""
PROBLEM:
--------
You receive raw customer data from an external source. Each record looks like this:

raw_records = [
    "   ORD_00123 | john.doe@EMAIL.COM |   (555) 123-4567   | $1,250.00 ",
    "  ORD_00456 |   JANE.SMITH@company.org | 555-987-6543 |$850.50   ",
    "ORD_00789|bob.wilson@Test.Net|(555)246-8135|  $2,100.75",
]

YOUR TASK:
----------
Write a function `clean_record(record: str) -> dict` that returns:

{
    "order_id": "00123",           # Remove "ORD_" prefix, strip whitespace
    "email": "john.doe@email.com", # Lowercase, strip whitespace
    "phone": "5551234567",         # Digits only
    "amount": "1250.00"            # Remove $, commas, strip whitespace
}

HINTS:
------
Use strip(), lower(), replace(), removeprefix(), and other methods from Section A.

EXPECTED OUTPUT:
----------------
For the first record, your function should return:
{
    "order_id": "00123",
    "email": "john.doe@email.com",
    "phone": "5551234567",
    "amount": "1250.00"
}
"""

# Test data
raw_records = [
    "   ORD_00123 | john.doe@EMAIL.COM |   (555) 123-4567   | $1,250.00 ",
    "  ORD_00456 |   JANE.SMITH@company.org | 555-987-6543 |$850.50   ",
    "ORD_00789|bob.wilson@Test.Net|(555)246-8135|  $2,100.75",
]


# -----------------------------------------------------------------------------
# STARTER CODE - Complete the TODO sections
# -----------------------------------------------------------------------------

def clean_record(record: str) -> dict:
    """
    Clean a raw customer record and return structured data.
    
    Args:
        record: Raw pipe-delimited string with order data
        
    Returns:
        Dictionary with cleaned order_id, email, phone, and amount
    """
    # Split by pipe delimiter
    parts = record.split("|")
    
    # TODO: Clean order_id - remove whitespace and "ORD_" prefix
    order_id = parts[0]
    
    # TODO: Clean email - remove whitespace and convert to lowercase
    email = parts[1]
    
    # TODO: Clean phone - extract digits only
    phone = parts[2]
    
    # TODO: Clean amount - remove $, commas, and whitespace
    amount = parts[3]
    
    return {
        "order_id": order_id,
        "email": email,
        "phone": phone,
        "amount": amount
    }


# -----------------------------------------------------------------------------
# SOLUTION (Don't peek until you've tried!)
# -----------------------------------------------------------------------------

def clean_record_solution(record: str) -> dict:
    """Solution for the clean_record challenge."""
    parts = record.split("|")
    
    # Clean order_id
    order_id = parts[0].strip().removeprefix("ORD_")
    
    # Clean email
    email = parts[1].strip().lower()
    
    # Clean phone - keep only digits
    phone = "".join(c for c in parts[2] if c.isdigit())
    
    # Clean amount
    amount = parts[3].strip().replace("$", "").replace(",", "")
    
    return {
        "order_id": order_id,
        "email": email,
        "phone": phone,
        "amount": amount
    }


# -----------------------------------------------------------------------------
# TEST YOUR SOLUTION
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    print("Testing clean_record function...")
    print("=" * 50)
    
    expected_results = [
        {"order_id": "00123", "email": "john.doe@email.com", "phone": "5551234567", "amount": "1250.00"},
        {"order_id": "00456", "email": "jane.smith@company.org", "phone": "5559876543", "amount": "850.50"},
        {"order_id": "00789", "email": "bob.wilson@test.net", "phone": "5552468135", "amount": "2100.75"},
    ]
    
    for i, record in enumerate(raw_records):
        result = clean_record(record)  # Change to clean_record_solution to see expected output
        expected = expected_results[i]
        
        print(f"\nRecord {i + 1}:")
        print(f"  Input:    '{record}'")
        print(f"  Output:   {result}")
        print(f"  Expected: {expected}")
        print(f"  Status:   {'✓ PASS' if result == expected else '✗ FAIL'}")
