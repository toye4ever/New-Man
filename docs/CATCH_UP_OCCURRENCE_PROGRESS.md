# Catch Me Up and repeated chapters

Unfinished readings preserve progress by ordered chapter occurrence, not a global
set of chapter names. If regrouping would put two separate occurrences of one
chapter into the same reading, they remain separate readings on that date. The
existing positional SQLite schema supports this. Completed readings retain their
history; equal-date order is stable.

Preview captures schedule inputs and per-reading progress. Apply rejects a
changed source, including progress on another repeat with the same globally
unique chapter keys. It also recomputes and compares the proposed schedule, so
altered preview progress cannot be applied. These are in-memory checks, not a
new schema revision or persisted token.

A legacy partial reading containing the same full chapter more than once has
only one stored chapter flag. There is no safe way to infer which occurrence
was completed. Catch Me Up rejects that ambiguous mapping and writes nothing;
it does not migrate, deduplicate or repair existing history. Other unmatched
or overlapping fragment mappings that cannot retain occurrence order likewise
require review rather than guessed completion.

SQLite regressions cover partial repeat progress, one remaining date, completed
history before/after an unfinished repeat, stale/altered previews and reload for
both canonical UUID and legacy input IDs. The latter exposed a lookup mismatch:
partial keys now use the projection's canonical plan ID during writes. No schema
or automatic migration is changed. Ordinary scheduling and local DST date
iteration retain their existing tests.


New plan generation now applies the same representational constraint: when a
full chapter repeats inside a proposed date's group, a new reading starts on
that same date. It does not move the chosen end date or reorder source chapters.
Ordinary unique full chapters stay grouped; intentional same-chapter verse
fragments keep their existing grouping. Reader and completion storage therefore
see each repeated full chapter in its own reading, without changing their UI or
inferring old progress. The old ambiguous-legacy rejection remains in place.

The creation acceptance test uses the actual Create Plan preview/apply and Plan
Details UI with temporary SQLite. It then opens the actual Reader with synthetic
content, completes only the first occurrence, reopens the database, and applies
Catch Me Up before a second reopen. No real Scripture/provider/device is used.
