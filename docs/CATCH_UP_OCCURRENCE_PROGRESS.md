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
