# Reflection 5 — Module 5: Normalization vs. Denormalization

## Take-away

Normalizing means that every fact is stored **once**: the site in the machine register, the price in the parts catalog, the work order header once with its list of parts underneath. Denormalizing copies facts back for read speed, but "faster" is an assumption that has to be measured.

## What was good?

The benchmark surprise: I expected the one-table shortcut to be faster, and it was slower (55.0 ms against 45.8 ms), used almost twice the space, and needed 4,000 row changes instead of 1 for a single fact. And the integrity check: 200,000 rows before and after normalizing, nothing lost.

## What was difficult?

Reading the dependencies that start from `job_id`: at first I thought the job told me nothing, until I compared only the rows with the same job_id. I also first thought each new table would still have 200,000 rows; the idea "each thing appears once" (50 machines, 20,000 work orders) and a five-row example made it click.

## Exploration and show stoppers

`technician → machine_id` looks like a rule in five rows, but it is only a coincidence: any technician can repair any machine. A dependency comes from the domain, not from a pattern. Also, the parts table had 10 rows, not 40 as the setup code seems to say.

## Interaction with peers and instructors

My pod: [Roberto Navia Guillén](https://github.com/RobertoNaviaGuillen/databases-portfolio), Levi, Ian and Sophia.

## How did you verify AI suggestions?

The module warns that an LLM can turn a pattern in a few sample rows into a "dependency"; I decided each FD from how a plant really works. For the benchmark I predicted first and then trusted only the measured numbers (3 runs each, the plans, `dbstat`), even when they contradicted the story's claim that the shortcut is faster.

## Help and extra work

Claude prepared the setup, normalization and benchmark scripts, adapted them to Windows and explained the concepts with workshop examples (asset register, parts catalog, work order header and list, reading a manual through its index); I made the predictions, ran everything and answered the questions in my own words.
