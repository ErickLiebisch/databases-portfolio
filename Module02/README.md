# Module 2 — Data Contracts & Reading Legacy Schemas

Session 2 of the HSBI Databases class. I audited a deliberately broken maintenance database (`legacy.db`), reconstructed the model its designer *meant*, proved its integrity defects with queries, and wrote the corrected schema as an executable data contract.

Course page: [Module 2 in the workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/02-data-contracts-and-legacy-schemas.md) · Pod mate: [Roberto Navia Guillén's portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio)

Rebuild the database: `sqlite3 Module02/legacy.db ".read Module02/legacy-setup.sql"` ([legacy-setup.sql](legacy-setup.sql))

## Learning Goals

<a id="lg1"></a>
### LG1 — `er-model`

Reconstruct an **ER/EER model** (entities, attributes, keys, relationships, cardinalities) from an undocumented SQL schema.

**Evidence:** [Task 1 — ER audit](#task-1)

<a id="lg2"></a>
### LG2 — `defects`

Identify **integrity defects** — missing foreign keys, orphan rows, redundant data, normalization violations — with queries, not intuition.

**Evidence:** [Task 2 — Defects](#task-2)

<a id="lg3"></a>
### LG3 — `keys`

Distinguish an **entity relationship** from an attribute, and a **surrogate key** from a natural key, and justify the choice.

**Evidence:** [Task 1 — ER audit](#task-1)

<a id="lg4"></a>
### LG4 — `contract`

Express a schema as a **code-first data contract** (Pydantic / SQLAlchemy) that an application can enforce.

**Evidence:** [Task 3 — Contract](#task-3)

<a id="lg5"></a>
### LG5 — `rules`

Write the **requirements the schema forgot**: the business rules nobody encoded.

**Evidence:** [Task 2 — Defects](#task-2), [Task 3 — Contract](#task-3)

<a id="task-1"></a>
## Task 1 — Reconstruct the ER model

**Proves:** [LG1](#lg1), [LG3](#lg3)

→ [er-audit.md](er-audit.md)

<a id="task-2"></a>
## Task 2 — Find the integrity defects with queries

**Proves:** [LG2](#lg2), [LG5](#lg5)

Queries: [audit-queries.sql](audit-queries.sql) → results: [audit-results.txt](audit-results.txt)

| # | Defect | Proof (query result) | What breaks in production |
|---|---|---|---|
| 1 | Orphan job | job 3 points to `cnc-05`, which is not in `machine` | the job cannot be assigned to a site or a machine history; nobody knows where the bearing went |
| 2 | Duplicate natural key | `P-1003` appears 2 times | stock counts and joins double; job 2 shows the coolant filter twice |
| 3 | Price stored as text | "price < 15" returns only P-1001 (12.50); P-1003 (9.90) is missing because '9' sorts after '1' | wrong invoices and cost reports, with no error message |
| 4 | Date that is not a date | `RANDOM-NAME` installed = `unknown` | maintenance intervals and machine age cannot be calculated |
| 5 | m:n hidden in a text list | the join on `parts_used` loses job 1 (`P-1001,P-1002`) silently | every multi-part job disappears from part-usage reports |

Forgotten business rules (LG5): every job must belong to an existing machine; a part number exists only once; prices are numbers ≥ 0; a job with `parts_used = NULL` is ambiguous (no parts used, or nobody wrote them down?).

<a id="task-3"></a>
## Task 3 — Write the data contract in code

**Proves:** [LG4](#lg4), [LG5](#lg5)

[contract.py](contract.py) → output: [contract-output.txt](contract-output.txt)

- **Pydantic (the application's contract):** the legacy machine row with `installed = "unknown"` is **rejected** before it reaches the database, and a serial number must start with `SN-`.
- **SQLAlchemy (the database's contract):** primary keys, `NOT NULL`, `UNIQUE(serial_no)`, `unit_price NUMERIC(9,2)`, a foreign key from `maint_job` to `machine`, and the junction table `job_part` with a composite key (`job_id`, `part_no`) that repairs the 1NF violation.

**Model vs. database:** format rules (a real date, the `SN-` prefix) live in the **model**, because the application can give the user a clear error message before saving. Rules that protect the relations between tables (primary keys, `UNIQUE`, foreign keys) live in the **database**, because they must hold no matter which program or person writes the data.

## Reflection

[Reflection 2](../Reflections/ref02.md)
