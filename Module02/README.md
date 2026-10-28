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

WIP

<a id="task-3"></a>
## Task 3 — Write the data contract in code

**Proves:** [LG4](#lg4), [LG5](#lg5)

[contract.py](contract.py) → output: [contract-output.txt](contract-output.txt)

WIP

## Reflection

[Reflection 2](../Reflections/ref02.md)
