# Module 5 — Normalization notes

## Task A — the five-row extract

| job_id | machine_id | site | technician | part_no | part_price |
|---|---|---|---|---|---|
| 1 | cnc-01 | Gütersloh | tech-0 | P-0001 | 6.00 |
| 1 | cnc-01 | Gütersloh | tech-0 | P-0002 | 7.00 |
| 2 | cnc-02 | Gütersloh | tech-1 | P-0001 | 6.00 |
| 2 | cnc-02 | Gütersloh | tech-1 | P-0003 | 8.50 |
| 3 | cnc-01 | Gütersloh | tech-0 | P-0003 | 8.50 |

### Functional dependencies (`X → Y`: same X always means same Y)

| Dependency | Guaranteed by the domain or only observed? | Why |
|---|---|---|
| `machine_id → site` | **domain** | a machine stands in one place (the asset register) |
| `part_no → part_price` | **domain** | the price is a property of the part, not of the job (the catalog) |
| `job_id → machine_id` | **domain** | a work order is done on one machine |
| `job_id → technician` | **domain** | a work order is done by one technician |
| `job_id → done_on` | **domain** | a work order has one date (in the 200k table) |
| `job_id ↛ part_no` | — | one job uses **several** parts |
| `part_price ↛ part_no` | — | two different parts can cost the same |
| `technician → machine_id` | **only observed** | in these 5 rows tech-0 always works on cnc-01, but any technician can repair any machine. It would only be a rule if the company decided it. This is the trap: an LLM looking only at the pattern can turn this coincidence into a "dependency". |

Candidate key of a row: `(job_id, part_no)`. `site` depends on the key only through a chain: `job_id → machine_id → site` (transitive dependency).

### The three anomalies

- **Update:** cnc-01 moves to Bielefeld. In the extract that means 3 rows (in the 200k table: **4,000 rows**). If someone changes only one, the table says cnc-01 is in two cities at once and nobody knows which is true.
- **Insert:** a new part P-0004 at €9.00 that no job has used yet cannot be recorded without inventing a job, a machine and a technician.
- **Delete:** cancelling job 1 deletes its two rows, and with them part P-0002 and its price €7.00 disappear from the system, although nobody asked for that.

### The normal forms, in my words

| Form | Simple rule | What I saw |
|---|---|---|
| 1NF | one cell = one value, no lists | `parts_used = 'P-1001,P-1002'` in Module 2 |
| 2NF | with a two-part key `(job_id, part_no)`, nothing may depend on only half of it | `part_price` depends only on `part_no` → own `part` table |
| 3NF | no chains: a non-key column may not depend on another non-key column | `job_id → machine_id → site` → `site` goes to the `machine` table |

## Task 1 — the 200k table

The same dependencies hold in `flat_jobpart` (200,000 rows = 20,000 jobs × 10 parts, 50 machines): `machine_id → site`, `part_no → part_price`, `job_id → machine_id`, `job_id → technician`, `job_id → done_on`. The fact "cnc-01 is in Gütersloh" is stored **4,000 times** (checked with `SELECT COUNT(*) FROM flat_jobpart WHERE machine_id = 'cnc-01'`).
