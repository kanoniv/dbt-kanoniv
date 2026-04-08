# E2E Identity Resolution Tutorial

Full identity resolution pipeline using `dbt-kanoniv` macros on the [kanoniv-examples](https://github.com/kanoniv/kanoniv-examples) dataset: 6,539 records across 5 source systems (CRM, Billing, Support, App, Partners) resolved into golden customer records.

## What This Demonstrates

This tutorial uses the `dbt-kanoniv` package for:

- **Normalization** - `normalize_email`, `normalize_name`, `normalize_phone` macros clean raw data
- **Validation** - `is_valid_email`, `is_valid_phone` flag bad data
- **Blocking keys** - `blocking_key`, `email_domain`, `name_initial` reduce O(n^2) comparisons
- **PII hashing** - `hash_pii` produces SHA-256 hashes for safe downstream use
- **Cross-DB compatibility** - `split_part`, `regexp_replace`, `concat_ws` work on Postgres, Snowflake, BigQuery

## Pipeline

```
seeds (10 CSVs)
  -> stg_identity__spine        (normalize + validate + block via dbt-kanoniv macros)
  -> int_identity__blocking     (candidate pairs via composite blocking keys)
  -> int_identity__scoring      (weighted scoring: email, phone, name, company)
  -> int_identity__clusters     (connected components via label propagation)
  -> dim_customers              (golden records via survivorship)
  -> fct_resolution_metrics     (merge rate, compression ratio, cluster stats)
```

## Results

| Metric | Value |
|--------|-------|
| Input records | 6,539 |
| Golden records | 2,922 |
| Merge rate | 55.3% |
| Compression ratio | 2.2x |
| Singletons | 1,248 |
| Merged clusters | 1,674 |
| Max cluster size | 9 |

## Prerequisites

- PostgreSQL 13+ with `fuzzystrmatch` and `pg_trgm` extensions
- Python 3.10+ with `dbt-postgres`

```bash
pip install dbt-postgres
```

## Quick Start

```bash
cd examples/e2e_tutorial

# Set Postgres connection (or edit profiles.yml)
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export POSTGRES_DB=dbt_tutorial

# Enable extensions
psql -d $POSTGRES_DB -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
psql -d $POSTGRES_DB -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Run the pipeline
dbt deps --profiles-dir .
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .

# Check results
psql -d $POSTGRES_DB -c "SELECT * FROM kanoniv_tutorial.fct_resolution_metrics;"
psql -d $POSTGRES_DB -c "SELECT * FROM kanoniv_tutorial.dim_customers LIMIT 10;"
```

## File Structure

```
e2e_tutorial/
  seeds/                              # 10 CSV files from kanoniv-examples
    crm_contacts.csv                  # 1,839 CRM contacts
    billing_accounts.csv              # 1,200 billing accounts
    support_users.csv                 # 1,400 support users
    app_signups.csv                   # 1,300 app signups
    partner_leads.csv                 # 800 partner leads
    + 5 enrichment tables
  models/
    staging/
      stg_identity__spine.sql         # Union + normalize with dbt-kanoniv macros
    intermediate/
      int_identity__blocking.sql      # Blocking with dbt-kanoniv blocking_key macro
      int_identity__scoring.sql       # Weighted pair scoring
      int_identity__clusters.sql      # Label propagation clustering
    marts/
      dim_customers.sql               # Golden records via survivorship
      fct_resolution_metrics.sql      # Resolution quality metrics
  tests/
    assert_merge_rate.sql             # Merge rate between 30-80%
    assert_golden_records_have_email.sql  # <15% missing emails
    assert_no_duplicate_source_records.sql  # No duplicates in clusters
```

## dbt-kanoniv Macros Used

| Macro | Where Used | Purpose |
|-------|-----------|---------|
| `normalize_email` | spine | Lowercase, trim, Gmail dot removal |
| `normalize_name` | spine | Uppercase, strip titles/suffixes |
| `normalize_phone` | spine | E.164 formatting |
| `is_valid_email` | spine | RFC format validation |
| `is_valid_phone` | spine | Digit count validation |
| `email_domain` | spine | Extract domain for blocking |
| `name_initial` | spine | First initial for blocking |
| `blocking_key` | blocking | Composite multi-field blocking |
| `hash_pii` | spine | SHA-256 PII hashing |
| `split_part` | spine, scoring | Cross-DB string splitting |
