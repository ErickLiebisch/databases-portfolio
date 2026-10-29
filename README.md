# Databases Portfolio — Erick Thomas Liebisch Jiménez

Personal portfolio for the **Databases (DBS, module 3386)** class at **HSBI Gütersloh**, winter semester 2026/27, taught by Prof. Dr. Ulrich Norbisrath.
Here I document what I build and measure in each module, with my reflections, so that every learning goal has visible evidence. I want to register my learning modules in this repo.

Course workbook: [syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [module index](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/00-index.md)

Author: Erick Thomas Liebisch Jiménez ([@ErickLiebisch](https://github.com/ErickLiebisch))

My Task Pod:
- Roberto Navia Guillén, [portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio)
- Levi (WIP)
- Ian (WIP)
- Sophia (WIP)

Final project repository: WIP.

## How to rebuild my environment

```sh
uv sync                 # installs Python 3.14 and the exact library versions from uv.lock
uv run uv-check.py      # prints the versions so you can verify the setup
```

Database files (`*.db`, `*.duckdb`) are not committed (see [.gitignore](.gitignore)); every database is rebuilt from the scripts in each module folder.

## Table of Contents

- [Module 1: Introduction & Local-First Foundations](Module01/README.md), [Reflection 1](Reflections/ref01.md)
- [Module 2: Data Contracts & Reading Legacy Schemas](Module02/README.md), [Reflection 2](Reflections/ref02.md)
- [Module 3: LLM-Assisted SQL & Query Profiling](Module03/README.md), [Reflection 3](Reflections/ref03.md)
- [Module 4: Data Integrity, Constraints & Edge Triggers](Module04/README.md), [Reflection 4](Reflections/ref04.md)
