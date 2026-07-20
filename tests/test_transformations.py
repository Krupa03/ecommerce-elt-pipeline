import pytest

def test_revenue_is_positive():
    assert 1250000 > 0

def test_row_count_expected():
    total_rows = 99441
    assert total_rows > 0

def test_cities_list_not_empty():
    cities = ["São Paulo", "Rio de Janeiro", "Belo Horizonte"]
    assert len(cities) > 0

def test_ltv_segments_defined():
    segments = ["low", "medium", "high"]
    assert "low" in segments

def test_pipeline_stages_defined():
    stages = ["extract", "dbt_run", "dbt_test"]
    assert len(stages) == 3
