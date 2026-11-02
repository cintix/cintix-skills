# Architectural Intent

> Part of the Modular Hybrid Architecture skill. Read this when you need the full statement of what the architecture optimizes for and what it deliberately rejects.

This architecture intentionally favors:

* local-first ownership
* strong feature ownership
* explicit module boundaries
* hidden implementation details
* understandable public surfaces
* module-owned persistence
* explicit data ownership
* DTO ownership
* controlled cross-module interaction
* acyclic dependencies
* explicit orchestration
* recoverable workflows
* developer-friendly filesystem navigation
* pragmatic internal architecture
* progressive structure
* architectural clarity over architectural purity
* scalability of understanding as the codebase grows

The architecture intentionally avoids:

* global horizontal business layers
* global infrastructure layers
* premature root-level shared structures
* premature root-level runtime structures
* speculative technical modules
* shared persistence models
* ownerless business DTOs
* cross-module repository access
* direct cross-module table access
* giant universal service interfaces
* interface-per-method ceremony
* hidden business orchestration in runtime
* global transactional assumptions
* uncontrolled event coupling
* circular module dependencies
* abstraction for abstraction's sake
* `shared`, `common`, `utils`, or similar folders becoming dumping grounds
* moving code outward merely because it uses technology
* structure created only to satisfy the architecture itself
* module bleeding
