# Reflection 2 — Module 2: Data Contracts & Reading Legacy Schemas

## Take-away

A database accepts almost anything if nobody writes the rules down. Defects should be **proved with queries**, not described: with 10 rows I could see them by eye, with 100,000 rows only a query can find them.

## What was good?

Finding the defects myself before running the queries (the duplicate part, the machine `cnc-05` that does not exist, the date "unknown", the list of two parts in one cell, the prices in quotes), and then seeing the contract reject the bad row exactly as I predicted.

## What was difficult?

Understanding the many-to-many relationship. What helped was the comparison with students and courses: one student has many courses and one course has many students, so you need a junction table with one row per pair (`job_part`).

## Exploration and show stoppers

The most surprising defect was the price stored as text: "price below 15" silently dropped the 9.90 filter because text is compared like a dictionary ('9' comes after '1'). No error, just a wrong answer.

## Interaction with peers and instructors

My pod: [Roberto Navia Guillén](https://github.com/RobertoNaviaGuillen/databases-portfolio), Levi, Ian and Sophia.

## How did you verify AI suggestions?

An AI can list these defects in seconds, but the list is not a proof. I verified every defect with its own query and result ([audit-results.txt](../Module02/audit-results.txt)), and I checked the contract by running it against a real bad row from the legacy data.

## Help and extra work

Claude prepared the setup and audit scripts and explained the ER concepts with examples; I ran them, predicted the results and answered the modeling questions (1:n, m:n, technician as an entity).
