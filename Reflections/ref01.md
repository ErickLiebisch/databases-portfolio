# Reflection 1 — Module 1: Introduction & Local-First Foundations

## Take-away

A database in SQLite is just one file. The script that builds it is the recipe and the `.db` file is the dish: I commit the recipe and rebuild the dish whenever I need it. My advice: commit often with clear messages, and keep databases, CSVs and secrets out of Git with `.gitignore`.

## What was good?

Seeing real numbers come out of my own queries: 172,800 readings loaded in one file of about 10.5 MB, and the worn bearing of cnc-02 visible in the alarm counts.

## What was difficult?

I started with no experience in databases, Git or the terminal. I created a file inside a duplicated `Module01/Module01` folder (relative paths), I first copied my README from the preview instead of the Markdown source, and I miscounted the rows twice before writing the units next to every number (s, readings, machines).

## Exploration and show stoppers

Rebuilding a new database (`copia.db`) from the `.dump` file showed me why the scripts, not the `.db` files, are the real evidence.

## Interaction with peers and instructors

My pod: [Roberto Navia Guillén](https://github.com/RobertoNaviaGuillen/databases-portfolio), Levi, Ian and Sophia. I invited the instructor as a collaborator on my portfolio.

## How did you verify AI suggestions?

I asked ChatGPT for the average night-time spindle load per machine. The query ran, but by checking which hours its filter really included (`MIN`/`MAX` of `time(ts)`) I found that it ignored the hours after midnight. With a real night shift (18:00–06:00) the ranking of the machines changed. I also used Claude as a tutor to guide the setup step by step.

## Help and extra work

Claude guided me through the setup (uv, Git, VS Code). I did the commits, ran every script and query myself and checked the results against my own calculations.
