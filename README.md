# dbt-kanoniv

> dbt package for [Kanoniv](https://kanoniv.com) identity resolution - normalization macros, blocking keys, validation helpers, and analytics models.

[![dbt Hub](https://img.shields.io/badge/dbt%20Hub-v0.2.0-orange)](https://hub.getdbt.com/kanoniv/dbt_kanoniv/latest/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/kanoniv/dbt-kanoniv/actions/workflows/ci.yml/badge.svg)](https://github.com/kanoniv/dbt-kanoniv/actions/workflows/ci.yml)

---

## What You Get

**Macros** (use standalone, no Kanoniv required):
- Normalize emails, phones, names, addresses across Postgres/Snowflake/BigQuery
- Generate blocking keys for efficient record comparison
- Validate formats, hash PII, extract components

**Models** (optional, requires Kanoniv database):
- Staging views over Kanoniv's 6 core tables
- Intermediate entity-source mapping and match summaries
- Mart tables: golden record overview, source lineage, match quality, batch performance

---

## Quick Start

```yaml
# packages.yml
packages:
  - git: "https://github.com/kanoniv/dbt-kanoniv.git"
    revision: v0.2.0
```

```bash
dbt deps
```

Then use the macros in your models:

```sql
select
    {{ dbt_kanoniv.normalize_email('email') }}   as clean_email,
    {{ dbt_kanoniv.normalize_phone('phone') }}   as clean_phone,
    {{ dbt_kanoniv.normalize_name('name') }}     as clean_name,
    {{ dbt_kanoniv.is_valid_email('email') }}     as email_ok,
    {{ dbt_kanoniv.email_domain('email') }}       as domain,
    {{ dbt_kanoniv.hash_pii('email') }}           as email_hash
from raw_contacts
```

---

## Tutorial: Identity Resolution on 6,539 Records

This walkthrough resolves customer records from 5 source systems (CRM, Billing, Support, App, Partners) into golden records using `dbt-kanoniv` macros. The full code is in [`examples/e2e_tutorial/`](examples/e2e_tutorial/).

### Prerequisites

- PostgreSQL 13+ with `fuzzystrmatch` and `pg_trgm` extensions
- Python 3.10+

```bash
pip install dbt-postgres
```

### Step 0: Set Up

```bash
# Clone the repo
git clone https://github.com/kanoniv/dbt-kanoniv.git
cd dbt-kanoniv/examples/e2e_tutorial

# Create a database
createdb dbt_tutorial
psql -d dbt_tutorial -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
psql -d dbt_tutorial -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Configure connection (or edit profiles.yml directly)
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export POSTGRES_DB=dbt_tutorial
```

### Step 1: Load the Data

The `seeds/` directory contains 10 CSV files - 6,539 records across 5 source systems. Same dataset used in the [kanoniv-examples](https://github.com/kanoniv/kanoniv-examples) comparison (dbt-sql vs Splink vs Kanoniv).

```bash
dbt deps --profiles-dir .
dbt seed --profiles-dir .
```

```
Completed successfully
Done. PASS=10 WARN=0 ERROR=0 SKIP=0 NO-OP=0 TOTAL=10
```

Here's what the raw data looks like:

| Source | Table | Records | Key Fields |
|--------|-------|---------|------------|
| CRM | `crm_contacts` | 1,839 | first_name, last_name, email, phone, company |
| Billing | `billing_accounts` | 1,200 | account_name ("Last, First"), email, company |
| Support | `support_users` | 1,400 | display_name ("First Last"), email, phone |
| App | `app_signups` | 1,300 | first_name, last_name, email |
| Partners | `partner_leads` | 800 | first_name, last_name, email, company |

The same person appears differently across systems: "John Smith" in CRM, "Smith, John" in Billing, "john.smith@gmail.com" in App signups.

### Step 2: Normalize and Validate (Staging)

`stg_identity__spine.sql` unions all 5 sources and applies `dbt-kanoniv` macros:

```sql
normalized as (
    select
        source_id,
        source_system,

        -- dbt-kanoniv normalization
        {{ dbt_kanoniv.normalize_name('first_name') }}    as first_name,
        {{ dbt_kanoniv.normalize_name('last_name') }}     as last_name,
        {{ dbt_kanoniv.normalize_email('email') }}         as email,
        {{ dbt_kanoniv.normalize_phone('phone') }}         as phone,

        -- dbt-kanoniv validation
        {{ dbt_kanoniv.is_valid_email('email') }}          as is_email_valid,
        {{ dbt_kanoniv.is_valid_phone('phone') }}          as is_phone_valid,

        -- dbt-kanoniv blocking keys
        {{ dbt_kanoniv.email_domain('email') }}            as email_domain,
        {{ dbt_kanoniv.name_initial('first_name') }}       as first_initial,

        -- dbt-kanoniv PII hashing
        {{ dbt_kanoniv.hash_pii('email') }}                as email_hash,

        md5(source_system || source_id)                    as record_id
    from raw_union
)
```

What each macro does:

| Before | Macro | After |
|--------|-------|-------|
| `John.Smith@Gmail.com` | `normalize_email` | `johnsmith@gmail.com` |
| `(555) 123-4567` | `normalize_phone` | `+15551234567` |
| `Dr. John Smith Jr` | `normalize_name` | `JOHN SMITH` |
| `john@acme.com` | `email_domain` | `acme.com` |
| `John` | `name_initial` | `J` |
| `john@acme.com` | `hash_pii` | `a3f2b7c8d9...` (SHA-256) |

Billing accounts have names in "Last, First" format. The `kanoniv_split_part` cross-DB macro handles the parsing:

```sql
-- Billing ("Last, First" in account_name)
trim({{ dbt_kanoniv.kanoniv_split_part('account_name', ',', 2) }})  as first_name,
trim({{ dbt_kanoniv.kanoniv_split_part('account_name', ',', 1) }})  as last_name,
```

### Step 3: Generate Candidate Pairs (Blocking)

`int_identity__blocking.sql` uses 5 blocking strategies to avoid comparing every record to every other record (6,539^2 = 42M pairs). Instead, it only compares records that share at least one blocking key:

```sql
-- Composite blocking key: first initial + last name
select
    record_id,
    {{ dbt_kanoniv.blocking_key(['first_initial', 'last_name']) }},
    'name'
from spine

-- Composite blocking key: email domain + last name
select
    record_id,
    {{ dbt_kanoniv.blocking_key(['email_domain', 'last_name']) }},
    'domain_name'
from spine

-- Composite blocking key: last name + company
select
    record_id,
    {{ dbt_kanoniv.blocking_key(['last_name', 'company_name']) }},
    'name_company'
from spine
```

The `blocking_key` macro concatenates fields with `|` separators using the cross-DB `concat_ws` dispatch. This produces ~17,700 candidate pairs (vs 42M brute force).

### Step 4: Score Pairs

`int_identity__scoring.sql` scores each candidate pair on 5 signals:

| Signal | Weight | Match Logic |
|--------|--------|-------------|
| Email | 5.0 | Exact match on normalized email |
| Email (username) | 3.0 | Same local part, different domain |
| Phone | 4.0 | Exact match on E.164 |
| First name | 2.0 | Trigram similarity |
| Last name | 2.0 | Trigram similarity |
| Company | 1.5 | Trigram similarity |

Pairs scoring >= 4.0 total are kept as matches (~5,900 pairs).

### Step 5: Cluster into Entities

`int_identity__clusters.sql` runs 6 passes of label propagation to find connected components. If A matches B and B matches C, they all get the same `resolved_entity_id`.

### Step 6: Survivorship (Golden Records)

`dim_customers.sql` picks the best value for each field from the cluster, prioritizing sources by trust:

```sql
first_value(email) over (
    partition by resolved_entity_id
    order by
        case source_system
            when 'crm'      then 1    -- CRM is most trusted
            when 'billing'  then 2
            when 'app'      then 3
            when 'support'  then 4
            when 'partners' then 5
        end,
        case when email is not null then 0 else 1 end
    rows between unbounded preceding and unbounded following
) as golden_email
```

### Step 7: Run It

```bash
dbt run --profiles-dir .
```

```
1 of 6 OK created sql view model stg_identity__spine ............ [CREATE VIEW]
2 of 6 OK created sql table model int_identity__blocking ........ [SELECT 17690]
3 of 6 OK created sql table model int_identity__scoring ......... [SELECT 5930]
4 of 6 OK created sql table model int_identity__clusters ........ [SELECT 6539]
5 of 6 OK created sql table model dim_customers ................. [SELECT 2922]
6 of 6 OK created sql table model fct_resolution_metrics ........ [SELECT 1]

Done. PASS=6 WARN=0 ERROR=0 SKIP=0 NO-OP=0 TOTAL=6
```

### Step 8: Validate

```bash
dbt test --profiles-dir .
```

```
Done. PASS=9 WARN=0 ERROR=0 SKIP=0 NO-OP=0 TOTAL=9
```

Tests verify:
- Merge rate is between 30-80% (sanity check)
- Less than 15% of golden records missing email
- No source record appears in multiple clusters
- All primary keys are unique and not null

### Step 9: Check Results

```bash
psql -d dbt_tutorial -c "SELECT * FROM kanoniv_tutorial.fct_resolution_metrics;"
```

```
 total_input_records | total_golden_records | merge_rate_pct | compression_ratio | singletons | merged_clusters | avg_cluster_size | max_cluster_size
---------------------+----------------------+----------------+-------------------+------------+-----------------+------------------+------------------
                6539 |                 2922 |           55.3 |               2.2 |       1248 |            1674 |             2.24 |                9
```

**6,539 source records resolved into 2,922 golden customers.** 55% merge rate, 2.2x compression.

```bash
psql -d dbt_tutorial -c "
  SELECT golden_first_name, golden_last_name, golden_email, golden_company
  FROM kanoniv_tutorial.dim_customers
  WHERE golden_company IS NOT NULL
  LIMIT 5;
"
```

---

## Macros Reference

### Normalization

| Macro | Example | Description |
|-------|---------|-------------|
| `normalize_email(col)` | `{{ dbt_kanoniv.normalize_email('email') }}` | Lowercase, trim, Gmail dot removal |
| `normalize_phone(col, country)` | `{{ dbt_kanoniv.normalize_phone('phone', 'US') }}` | E.164 formatting (US/CA/UK) |
| `normalize_name(col)` | `{{ dbt_kanoniv.normalize_name('name') }}` | Uppercase, strip titles/suffixes |
| `normalize_address(col)` | `{{ dbt_kanoniv.normalize_address('addr') }}` | Uppercase, abbreviate street types |

### Blocking Keys

| Macro | Example | Description |
|-------|---------|-------------|
| `blocking_key(fields)` | `{{ dbt_kanoniv.blocking_key(['domain', 'zip']) }}` | Composite key from multiple fields |
| `email_domain(col)` | `{{ dbt_kanoniv.email_domain('email') }}` | Extract domain |
| `phone_area_code(col)` | `{{ dbt_kanoniv.phone_area_code('phone') }}` | Extract US area code |
| `name_initial(col, pos)` | `{{ dbt_kanoniv.name_initial('name', 'first') }}` | First or last initial |

### Validation

| Macro | Example | Description |
|-------|---------|-------------|
| `is_valid_email(col)` | `{{ dbt_kanoniv.is_valid_email('email') }}` | RFC format check |
| `is_valid_phone(col)` | `{{ dbt_kanoniv.is_valid_phone('phone') }}` | 10+ digit check |

### Utilities

| Macro | Example | Description |
|-------|---------|-------------|
| `hash_pii(col, salt)` | `{{ dbt_kanoniv.hash_pii('email', salt='x') }}` | SHA-256 hash |
| `last_n_digits(col, n)` | `{{ dbt_kanoniv.last_n_digits('ssn', 4) }}` | Extract last N digits |
| `age_from_dob(col)` | `{{ dbt_kanoniv.age_from_dob('dob') }}` | Age in years |

### Cross-DB Helpers

These are used internally by other macros but available for direct use:

| Macro | Postgres | Snowflake | BigQuery |
|-------|----------|-----------|----------|
| `kanoniv_split_part` | `split_part()` | `split_part()` | `SPLIT(...)[SAFE_OFFSET()]` |
| `kanoniv_regexp_replace` | `regexp_replace()` | `REGEXP_REPLACE()` | `REGEXP_REPLACE()` |
| `kanoniv_hash_sha256` | `encode(sha256(), 'hex')` | `sha2()` | `TO_HEX(SHA256())` |
| `kanoniv_concat_ws` | `concat_ws()` | `concat_ws()` | `ARRAY_TO_STRING()` |
| `kanoniv_regexp_match` | `~` | `RLIKE()` | `REGEXP_CONTAINS()` |

---

## Models

Models are **disabled by default**. To enable, add to your `dbt_project.yml`:

```yaml
vars:
  kanoniv_enable_models: true

models:
  dbt_kanoniv:
    +enabled: true
```

Configure which tables to read:

```yaml
vars:
  kanoniv_schema: 'public'
  kanoniv_external_entities_table: 'external_entities'
  kanoniv_canonical_entities_table: 'canonical_entities'
  kanoniv_identity_links_table: 'identity_links'
  kanoniv_match_results_table: 'match_results'
  kanoniv_data_sources_table: 'data_sources'
  kanoniv_batch_runs_table: 'batch_runs'
```

### Model DAG

```
Sources (6 Kanoniv tables)
  -> stg_kanoniv__external_entities     (view)
  -> stg_kanoniv__canonical_entities    (view)
  -> stg_kanoniv__identity_links        (view)
  -> stg_kanoniv__match_results         (view)
  -> stg_kanoniv__data_sources          (view)
  -> stg_kanoniv__batch_runs            (view)
      -> int_kanoniv__entity_source_map (view)   -- links + entities + sources
      -> int_kanoniv__match_summary     (view)   -- match stats per batch
          -> kanoniv__canonical_overview (table)  -- golden records + source counts
          -> kanoniv__source_lineage    (table)  -- full source-to-entity mapping
          -> kanoniv__match_quality     (table)  -- match metrics per batch
          -> kanoniv__batch_performance (table)  -- batch operational metrics
```

### Mart Descriptions

| Model | Rows | Description |
|-------|------|-------------|
| `kanoniv__canonical_overview` | 1 per entity | Golden records enriched with source_record_count, source_count, first/last seen timestamps |
| `kanoniv__source_lineage` | 1 per link | Full audit trail: which source record mapped to which entity, with confidence and link type |
| `kanoniv__match_quality` | 1 per batch+decision | Match decision counts and average confidence, grouped by batch and decision type |
| `kanoniv__batch_performance` | 1 per batch | Duration, status, total comparisons, average score per reconciliation run |

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

## Configuration

```yaml
vars:
  kanoniv_default_country: 'US'           # Phone normalization default
  kanoniv_email_normalize_gmail: true     # Remove dots from Gmail local parts
  kanoniv_enable_models: false            # Enable analytics models
  kanoniv_schema: 'public'               # Schema containing Kanoniv tables
```

---

## Requirements

- dbt >= 1.3.0, < 2.0.0
- One of: dbt-postgres, dbt-snowflake, dbt-bigquery

---

## License

Apache License 2.0 - see [LICENSE](LICENSE)
