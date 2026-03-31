# CLAUDE.md — Phoenix Analytics

OBSIDIAN_PAD: C:\Users\Rudy\Documents\Obsidian\BenEnFrits\BenEnFrits_Brain\RJW BV\Phoenix-Analytics\

## Stack
Elixir/Phoenix + Ash Framework. Volg de Project Magnitude filosofie.
Zie: C:\Users\Rudy\Documents\Obsidian\BenEnFrits\BenEnFrits_Brain\_GLOBAAL\MAGNITUDE_BLUEPRINT.md

## Poorten
- App (dev): 4095
- PostgreSQL: 5445
- Mailpit SMTP: 1034 / UI: 8034

## Regels
- Geen pushes naar main zonder expliciete toestemming
- mix format voor elke commit
- Obsidian BACKLOG + LEERPUNTEN bijwerken na elke sessie
- Versienummer bumpen in footer bij elke push naar cloud
- Nooit raw IP adressen opslaan (AVG) -- alleen dagelijks geroteerd hash
- Nooit PII in Oban job args of logs

## Fly.io apps
- Staging: phoenix-analytics-staging (develop branch)
- Productie: phoenix-analytics (main branch)

## Privacy aanpak
- Cookieloos: geen tracking cookies, geen cookiebanner nodig
- Session hashing: IP + UA + dagelijks zout (SHA-256), nooit raw opslaan
- Geen PII in events/pageviews

## A/B Testing
- Variant toewijzing: deterministisch via :erlang.phash2({session_hash, experiment_id}, 100)
- Sticky per sessie zonder cookie
- Conversies koppelen via experiment_id + variant_name in Event resource
