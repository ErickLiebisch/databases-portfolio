# Reflection 3 — Module 3: LLM-Assisted SQL & Query Profiling

## Take-away

`EXPLAIN QUERY PLAN` lets me ask the database *how* it will search before it searches. `SCAN` means reading everything, `SEARCH … USING INDEX` means jumping straight to the rows, like the index of a service manual. And never build SQL by pasting user text: always use `?`.

## What was good?

Seeing the plan change from `SCAN` to `SEARCH USING INDEX` and the time drop from 1.55 ms to 0.14 ms. And seeing the injection attack return all 2,000 customers, while the safe version returned nothing.

## What was difficult?

Understanding why an index does not always help. The manual comparison helped: if I need 500 of 600 pages, the index is useless. I also predicted that the attack would return only 1 customer, and it returned all of them.

## Exploration and show stoppers

A real surname like `O'Brien` already crashes the vulnerable version: injection is not only an attack problem, it is also a normal-data bug.

## Interaction with peers and instructors

My pod: [Roberto Navia Guillén](https://github.com/RobertoNaviaGuillen/databases-portfolio), Levi, Ian and Sophia.

## How did you verify AI suggestions?

I did not trust "an index makes it faster": I measured 3 runs per case, used the median, and checked the plan. For the dashboard query the index changed nothing, and I documented that negative result. The ChatGPT query from Module 1 taught me to check what a filter really includes.

## Help and extra work

Claude prepared the setup, benchmark and injection scripts and explained the concepts with examples (service manual, cold engine, work-order form); I ran everything, made predictions first and answered the questions in my own words.
