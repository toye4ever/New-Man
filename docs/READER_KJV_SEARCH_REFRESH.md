# Reader KJV search after installation

A mounted Reader's default search retained both ScriptureSearch's verse list and
its captured KjvScriptureService's memoized first source. Searching the bundled
sample before installation therefore left repeated and new lexical queries on
the sample after a full install; passage reload alone did not refresh search.

After a successful KJV install that reports installed-offline availability, the
Reader now replaces only its owned default KJV search and captured loader. It
keeps injected search objects/caches, query controls and Reader state. Rejected
packages do not reset it.
The handler's setState callback also now returns void, fixing the debug assertion
observed on the same successful-install path. NLT and canonical validation code
are unchanged. There is no new active-download cancellation API or behavior.

Widget regressions use the existing bundled sample and deterministic complete
synthetic VPL fixture through the real converter/recoverable file installation,
mock HTTP and owned temporary support directory. They verify initial sample
hits, full-only misses, rejected install/cache preservation, same mounted Reader,
immediate repeated/new queries after success and injected-search preservation.
No provider request, voice discovery, content rights or device action is involved.
The test is bounded and cleans its owned files/providers. This is portable
Reader behavior evidence, not Galaxy/Windows runtime or full-MVP qualification.
