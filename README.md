# dbt-kanoniv

> dbt package for Kanoniv identity data modeling.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/kanoniv/dbt-kanoniv/actions/workflows/ci.yml/badge.svg)](https://github.com/kanoniv/dbt-kanoniv/actions/workflows/ci.yml)

---

## Overview

This dbt package provides:

- **Normalization macros** — Email, phone, name, and address standardization
- **Blocking key generators** — For efficient candidate pair generation
- **Validation macros** — Email and phone format checks
- **Utility macros** — PII hashing, digit extraction, age calculation
- **Staging & mart models** — Ready-to-use analytics models for Kanoniv engine output

All macros are **cross-database compatible** via a dispatch layer.

> **Note**: This package prepares and analyses data around Kanoniv. Actual identity resolution requires the [Kanoniv engine](https://github.com/kanoniv/kanoniv-engine).

---

## Installation

Add to your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/kanoniv/dbt-kanoniv.git"
    revision: v0.1.0
```

Then run:

```bash
dbt deps
```

---

## Supported Warehouses

| Warehouse | Status |
|-----------|--------|
| PostgreSQL | Fully supported |
| Snowflake | Supported |
| BigQuery | Supported |
| Redshift | Planned |
| Databricks | Planned |

---

## Usage

### Normalization Macros

```sql
-- Normalize email (lowercases, trims, strips Gmail dots)
select {{ dbt_kanoniv.normalize_email('email') }} as email_normalized

-- Normalize phone to E.164
select {{ dbt_kanoniv.normalize_phone('phone', 'US') }} as phone_normalized

-- Normalize name (uppercase, strip titles/suffixes)
select {{ dbt_kanoniv.normalize_name('full_name') }} as name_normalized

-- Normalize address (uppercase, abbreviate street types)
select {{ dbt_kanoniv.normalize_address('address') }} as address_normalized
```

### Blocking Keys

```sql
-- Composite blocking key
select {{ dbt_kanoniv.blocking_key(['email_domain', 'zip_code']) }} as block_key

-- Individual components
select {{ dbt_kanoniv.email_domain('email') }} as domain
select {{ dbt_kanoniv.phone_area_code('phone') }} as area_code
select {{ dbt_kanoniv.name_initial('name', 'first') }} as first_initial
```

### Validation

```sql
select *
from customers
where {{ dbt_kanoniv.is_valid_email('email') }}
  and {{ dbt_kanoniv.is_valid_phone('phone') }}
```

### Utilities

```sql
-- Hash PII for privacy-safe matching
select {{ dbt_kanoniv.hash_pii('email', salt='my_salt') }} as email_hash

-- Last 4 digits (SSN, card number)
select {{ dbt_kanoniv.last_n_digits('ssn', 4) }} as ssn_last4

-- Age from date of birth
select {{ dbt_kanoniv.age_from_dob('date_of_birth') }} as age
```

---

## Available Macros

### Normalization

| Macro | Description |
|-------|-------------|
| `normalize_email(col)` | Lowercase, trim, optionally remove Gmail dots |
| `normalize_phone(col, country)` | Format to E.164 with country prefix |
| `normalize_name(col, strip_extra)` | Uppercase, optionally strip titles/suffixes |
| `normalize_address(col)` | Uppercase, abbreviate street types |

### Blocking Keys

| Macro | Description |
|-------|-------------|
| `blocking_key(fields)` | Composite blocking key from multiple fields |
| `email_domain(col)` | Extract domain from email address |
| `phone_area_code(col)` | Extract US area code |
| `name_initial(col, position)` | First or last name initial |

### Validation

| Macro | Description |
|-------|-------------|
| `is_valid_email(col)` | Regex email format validation |
| `is_valid_phone(col)` | Check phone has 10+ digits |

### Utilities

| Macro | Description |
|-------|-------------|
| `hash_pii(col, salt)` | SHA-256 hash with optional salt |
| `last_n_digits(col, n)` | Extract last N digits from string |
| `age_from_dob(col)` | Calculate age in years |

---

## Models

Models are **disabled by default**. To enable them, set the following variable in your `dbt_project.yml`:

```yaml
vars:
  kanoniv_enable_models: true
```

You must also configure the source schema and table names to match your Kanoniv database:

```yaml
vars:
  kanoniv_enable_models: true
  kanoniv_schema: 'public'
  kanoniv_external_entities_table: 'external_entities'
  kanoniv_canonical_entities_table: 'canonical_entities'
  kanoniv_identity_links_table: 'identity_links'
  kanoniv_match_results_table: 'match_results'
  kanoniv_data_sources_table: 'data_sources'
  kanoniv_batch_runs_table: 'batch_runs'
```

### Available Models

| Layer | Model | Description |
|-------|-------|-------------|
| Staging | `stg_kanoniv__external_entities` | External entities source data |
| Staging | `stg_kanoniv__canonical_entities` | Canonical entities source data |
| Staging | `stg_kanoniv__identity_links` | Identity links source data |
| Staging | `stg_kanoniv__match_results` | Match results source data |
| Staging | `stg_kanoniv__data_sources` | Data sources source data |
| Staging | `stg_kanoniv__batch_runs` | Batch runs source data |
| Intermediate | `int_kanoniv__entity_source_map` | Source records mapped to canonical entities |
| Intermediate | `int_kanoniv__match_summary` | Match decisions aggregated per batch |
| Mart | `kanoniv__canonical_overview` | Golden records with source counts |
| Mart | `kanoniv__source_lineage` | Complete source-to-canonical mapping |
| Mart | `kanoniv__match_quality` | Match quality metrics per batch |
| Mart | `kanoniv__batch_performance` | Operational metrics per batch run |

---

## Configuration

```yaml
vars:
  # Normalization
  kanoniv_default_country: 'US'          # Default country for phone normalization
  kanoniv_email_normalize_gmail: true    # Remove dots from Gmail addresses

  # Models
  kanoniv_enable_models: false           # Enable/disable all models
  kanoniv_schema: 'public'              # Schema containing Kanoniv tables
```

---

## Requirements

- dbt >= 1.3.0
- One of: dbt-postgres, dbt-snowflake, dbt-bigquery

---

## License

Apache License 2.0 — see [LICENSE](LICENSE)

---

## Related

| Repo | Description |
|------|-------------|
| [kanoniv-spec](https://github.com/kanoniv/kanoniv-spec) | YAML language specification |
| [kanoniv-engine](https://github.com/kanoniv/kanoniv-engine) | Identity resolution engine |
| [python-sdk](https://github.com/kanoniv/python-sdk) | Python SDK |
