import pytest
from datetime import datetime

# This import will fail until the function is implemented
from convert_log_to_parquet.convert_log_to_parquet import validate_record

# Define the allowed activity types for tests
ALLOWED_ACTIVITY_TYPES = {'login', 'logout', 'purchase', 'view_page'}

# --- Test Cases ---

@pytest.fixture
def valid_record():
    """Provides a valid record for testing."""
    return {
        "timestamp": datetime.now().isoformat() + "Z",
        "user_id": "user123",
        "activity_type": "login"
    }

def test_valid_record(valid_record):
    """
    Tests that a completely valid record passes validation.
    """
    is_valid, reason = validate_record(valid_record, ALLOWED_ACTIVITY_TYPES)
    assert is_valid is True
    assert reason == ""

def test_missing_required_key(valid_record):
    """
    Tests that a record with a missing required key fails validation.
    """
    del valid_record["user_id"]
    is_valid, reason = validate_record(valid_record, ALLOWED_ACTIVITY_TYPES)
    assert is_valid is False
    assert "Missing required key" in reason

def test_invalid_timestamp_format(valid_record):
    """
    Tests that a record with an invalid timestamp format fails validation.
    """
    valid_record["timestamp"] = "2025-07-28 10:30:00"  # Not ISO 8601 format
    is_valid, reason = validate_record(valid_record, ALLOWED_ACTIVITY_TYPES)
    assert is_valid is False
    assert "Invalid timestamp format" in reason

def test_invalid_activity_type(valid_record):
    """
    Tests that a record with an activity_type not in the allowed list fails validation.
    """
    valid_record["activity_type"] = "unknown_action"
    is_valid, reason = validate_record(valid_record, ALLOWED_ACTIVITY_TYPES)
    assert is_valid is False
    assert "Invalid activity_type" in reason

def test_empty_record():
    """
    Tests that an empty dictionary fails validation.
    """
    is_valid, reason = validate_record({}, ALLOWED_ACTIVITY_TYPES)
    assert is_valid is False

@pytest.mark.parametrize("key_to_nullify", ["timestamp", "user_id", "activity_type"])
def test_null_values(valid_record, key_to_nullify):
    """
    Tests that a record with null values for required keys fails validation.
    """
    valid_record[key_to_nullify] = None
    is_valid, reason = validate_record(valid_record, ALLOWED_ACTIVITY_TYPES)
    assert is_valid is False
    assert "is null" in reason

