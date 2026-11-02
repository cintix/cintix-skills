# Language Mappings

> Part of the Modular Hybrid Architecture skill. Read this when translating the architecture into a specific language or framework's idioms.

## Java

Use:

* packages as module boundaries
* public contracts near module roots
* module-owned shared DTO packages where required
* package-private or internal implementations where practical
* local runtime inside modules where ownership is local
* root runtime only for shared execution contexts
* architecture tests such as ArchUnit where useful

---

## C#

Use:

* namespaces or projects as module boundaries
* public contract namespaces
* internal implementations
* dependency injection for composition
* shared contract namespaces only where cross-module use exists
* local executable/runtime projects or folders where appropriate
* architecture tests where useful

Do not require separate Infrastructure projects merely because Clean Architecture commonly uses them.

---

## Node / NestJS

Use:

* feature modules
* exported providers or contracts only where cross-module access is required
* private internal providers
* explicit public events
* DTO sharing only where real consumers exist
* module-local bootstrap/runtime where execution belongs to one module
* shared runtime only when several modules are composed into the same execution context

Do not create global provider modules simply to collect technical code.

---

## Go

Use:

* package boundaries
* exported APIs only when cross-package consumption is intentional
* internal packages
* explicit composition
* local command/runtime ownership where possible
* shared boundary structs only when genuinely shared
* narrow capability-oriented interfaces where useful
