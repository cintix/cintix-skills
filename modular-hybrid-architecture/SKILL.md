# Modular Hybrid Architecture Skill

## Purpose

Use this skill to design or refactor applications into a modular monolith that combines:

* feature-module ownership (NestJS-style)
* clean contracts with hidden implementation (C# clean architecture style)
* internal clean architecture principles inside each module
* pragmatic service-oriented orchestration without excessive layering

---

## Core Rules

1. Organize by feature/domain, not horizontal technical layers.
2. Each module root contains exactly one `.java` file: the module's public contract interface.
3. The module root contract represents the only public entry point into the module.
4. Module root must not contain models, managers, factories, controllers, workers, or implementation classes.
5. The implementation of the module-root contract interface must live inside the module's `services` package and acts as the module facade.
6. Implementation lives in `services`.
7. Persistence/data access lives in `services/persistence`.
8. Other modules may depend only on module-root contracts.
9. No cross-module imports of another module's internals.
10. Persistence entities and internal models must never leak outside the module boundary.
11. Shared technical code is allowed only in `infrastructure`, and infrastructure may not depend on module internals.
12. Only the composition root may instantiate or wire implementations across module boundaries.
13. Composition root wires modules together (e.g. `infrastructure/modules/ModuleRegistry.java`).

---

## Standard Module Layout

```text
<module>/
  <ModuleContractInterface>.java

  endpoint/

  services/
    <ModuleContractInterface>Service.java

    domain/
      models/
      rules/
      events/

    persistence/
      entities/
      repositories/
      managers/
      mappers/
```

---

## Infrastructure Layout

```text
infrastructure/
  logging/
  persistence/
  annotations/
  modules/
```

---

## Internal Module Architecture

Each module should internally follow clean architecture principles while remaining pragmatic and lightweight.

The module root contract is the public boundary.
Inside the module, dependencies must point inward toward business logic and domain rules.

Avoid unnecessary abstraction layers, command-handler explosion, or artificial architectural ceremony.

---

## Internal Dependency Rules

1. `endpoint` may call internal services or the module facade service.
2. Internal services may depend on `domain` and module-private contracts/interfaces.
3. `domain` must not depend on `endpoint`, `persistence`, frameworks, infrastructure, or other module internals.
4. `persistence` implements module-private persistence concerns and may map between entities and domain models.
5. Persistence entities must remain internal to the module.
6. Other modules may still depend only on the module-root contract.
7. The module-root contract should expose behavior, not internal entities.
8. Infrastructure may provide technical capabilities but must not contain feature business logic.

---

## Standard Dependency Flow

```text
Other Modules
        ↓
Module Contract Interface
        ↓
Module Facade Service
        ↓
Internal Services
        ↓
Domain
        ↓
Persistence
```

---

## Refactor Workflow

1. Map module boundaries and violations.
2. Define module-root contracts.
3. Move implementations behind contracts.
4. Move each module's persistence into `services/persistence`.
5. Extract shared technical code into `infrastructure`.
6. Move all cross-module wiring/factory creation to composition root (registry/bootstrap).
7. Verify dependency direction inside modules.
8. Remove unnecessary abstractions and simplify orchestration where possible.
9. Run full build and integration checks.

---

## Decision Heuristics

* If code expresses business capability, keep it inside the owning feature module.
* If code is technical and reusable without knowing any module, place it in `infrastructure`.
* If another module needs behavior, expose it through the module-root contract.
* If another module needs data, expose behavior instead of sharing entities.
* Put orchestration inside internal services.
* Put framework adapters in `endpoint` and `persistence`.
* Keep persistence entities separate from domain models when behavior or invariants matter.
* Prefer exposing operations through the module contract instead of sharing internal state.
* Prefer simple service coordination over excessive architectural patterns.
* Avoid creating abstractions unless they protect a real boundary or simplify ownership.

---

## Language Mapping

* Java: packages + one module-root interface + registry-based wiring.
* C#: namespaces/projects + DI + contracts.
* Node/NestJS: module exports/providers + boundary discipline.
* Go: package boundaries + interface-first module roots.

---

## Notes

This pattern intentionally favors:

* strong module ownership
* hidden implementation details
* explicit contracts
* clean dependency direction
* composition-root orchestration
* feature-oriented structure
* pragmatic modularity over architectural purity

This pattern does not require architecture-enforcement tooling by default.
Use code review and structural discipline as the primary guardrail unless the team explicitly opts into automated boundary checks.
