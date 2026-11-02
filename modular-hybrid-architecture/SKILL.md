---
name: modular-hybrid-architecture
description: Design or refactor applications into a modular monolith using local-first ownership, explicit public module contracts, hidden internals, module-owned data and transactions, and explicit cross-module orchestration. Use when defining module boundaries, deciding what belongs in shared/ or runtime/, reviewing dependency direction, or planning an architecture refactor.
---

# Modular Hybrid Architecture

## Purpose

Use this skill to design or refactor applications into a modular architecture that combines:

* feature-module ownership
* explicit public module contracts
* hidden module implementation
* internal clean architecture principles where they add value
* pragmatic service-oriented orchestration without excessive layering
* strong data ownership and explicit workflow coordination
* local-first organization
* progressive structure that grows only when responsibilities actually cross module boundaries
* clear filesystem navigation for developers

The architecture prioritizes **ownership, locality, module boundaries, controlled dependencies, developer readability, and maintainability at scale** over architectural ceremony.

The primary goal is not to force a specific folder template.

The goal is to make the correct ownership of code obvious and keep responsibilities as local as possible.

## When to use

Use this skill when:

* designing the structure of a new application or subsystem
* refactoring a layered monolith into feature-owned modules
* reviewing module boundaries, imports, folder structure, and shared types
* deciding where runtime, transactions, events, workflows, and technical capabilities belong
* introducing automated boundary enforcement

Do not use it to choose a deployment topology or distributed-systems pattern. The architecture is a modular monolith model; it can inform service boundaries, but it does not prescribe how services are deployed or communicate.

---

# Core Principles

1. Organize by feature or domain capability, not global horizontal technical layers.
2. Keep code inside the module that owns it unless there is a genuine reason to share it.
3. A module owns its business logic, domain models, persistence, data, local runtime concerns, and local transactions.
4. Public module contracts expose only the capabilities other modules legitimately need.
5. Other modules must never depend on another module's internal implementation.
6. Persistence entities and internal domain models must never leak outside the owning module.
7. Shared DTOs may cross module boundaries, but every business DTO must have exactly one owning module.
8. Shared DTOs are transport and boundary types only and must not become a shared domain model.
9. Runtime follows ownership and remains inside a module unless runtime responsibility genuinely spans multiple modules.
10. Cross-module business orchestration belongs to the module that owns the business outcome.
11. Cyclic module dependencies are forbidden.
12. Each module owns its own data consistency and local transactions.
13. Cross-module workflows must explicitly consider partial failure where correctness requires it.
14. Orchestration modules may own workflow state but must never become owners of participating modules' business data.
15. Structure should grow with complexity rather than manufacture complexity.
16. The filesystem is part of the architecture and should help developers understand ownership and navigate the system.
17. Architectural containers should exist because responsibilities require them, not because a reference layout contains them.
18. Prefer explicit principles over premature architectural rules.

---

# Local First

Local First is a central principle of this architecture.

Code should remain at the narrowest valid ownership scope.

If something belongs to only one module, it stays inside that module.

This applies to models, DTOs, services, persistence, runtime, configuration, messaging, integrations, workers, technical helpers, and framework adapters.

```text
customers/
  Customers.java

  models/
    Customer.java
    CustomerDto.java

  services/
    CustomersService.java

  persistence/
    CustomerEntity.java
    CustomerRepository.java

  runtime/
    Main.java
```

If no other module consumes `CustomerDto`, there is no reason to move it into `shared`.

If the runtime exists only to run Customers, there is no reason to create a root-level `runtime`.

If database or messaging code is used only by Customers, there is no reason to create a global technical module for it.

Core rule:

> Keep responsibility inside its owning module until a real cross-module responsibility exists.

---

# Module Bleeding

**Module Bleeding** is the unnecessary movement of module-owned concerns outside their owning module.

Examples:

```text
shared/customers/CustomerDto   when only Customers uses the DTO
runtime/customer-worker       when the worker belongs only to Customers
modules/database              when only one module uses the database capability
common/CustomerMapper         when the mapper exists only for Customers
```

Module bleeding weakens locality and makes ownership harder to understand.

It often happens because code is moved outward:

* in anticipation of future reuse
* because it looks more architecturally organized
* because something uses a technical framework
* because two implementations look similar
* because a reference architecture contains a corresponding folder

Core rule:

> Do not move code outward merely because it could theoretically be reused.

---

# Architectural Promotion

Responsibilities may move outward when their ownership genuinely expands.

```text
local module responsibility
        ↓
real cross-module need appears
        ↓
promote outward
```

A local `customers/models/CustomerDto` may later become `shared/customers/CustomerDto` when other modules legitimately consume it.

An `orders/runtime/worker` stays inside Orders while only Orders owns it. A root-level runtime becomes appropriate only when the runtime itself spans multiple modules.

Promotion is intentional architectural evolution. It should not be speculative.

---

# Progressive Structure

The architecture does not require every project to contain:

```text
shared/
modules/
runtime/
```

These are available structural concepts, not mandatory root folders.

A small application may simply be:

```text
customers/
  Customers.java
  models/
  services/
  persistence/
  runtime/
```

That may already satisfy the architecture completely. Root-level `modules/`, `shared/`, and `runtime/` appear when grouping, boundary data, or shared execution actually require them.

Core rule:

> Folders are created because boundaries exist.

> Boundaries are not invented because folders exist in the reference architecture.

---

# Structural Readability

Architecture exists for developers as well as compilers.

A developer should be able to inspect the project structure and quickly answer:

```text
Where does this capability belong?
Who owns this model?
Is this type shared?
Does this runtime belong to one module or several?
What may another module consume?
Where is the implementation hidden?
```

The theoretically pure location is not always the most useful location for humans. Consistency, discoverability, and readability are legitimate architectural concerns.

Core rule:

> A good architecture should make the right place for new code feel obvious.

The filesystem is part of the architecture contract.

---

# What a Module Exposes

A module's public API consists of:

```text
module public contracts
+
module public events
+
module-owned shared boundary DTOs
```

Public contracts and public events stay visible near the module root. Implementations stay hidden inside `services/`, `domain/`, `persistence/`, and similar packages.

Other modules may import `orders.Orders` and `orders.OrderQueries`. They may not import `orders.services.OrdersService`, `orders.services.persistence.OrderRepository`, or `orders.services.domain.Order`.

For the rules on contracts, shared DTOs, internal architecture, technical capabilities, and runtime placement, read `references/module-boundaries.md` and `references/runtime-and-technical.md`.

---

# How to Apply

## Design / Refactor Workflow

1. Identify business capabilities and current ownership.
2. Identify module boundaries.
3. Keep existing behavior local unless there is a real reason to move it outward.
4. Map cross-module dependencies.
5. Identify ownership violations.
6. Identify module bleeding.
7. Identify direct cross-module persistence access.
8. Define public contracts only where other modules need behavior.
9. Define shared boundary DTOs only where genuine cross-module data consumption exists.
10. Keep non-shared DTOs inside their owning module.
11. Move implementations behind public module contracts.
12. Move business logic into the owning module.
13. Keep module-specific persistence inside the module.
14. Keep module-specific technical behavior inside the module.
15. Extract a reusable technical module only when genuine shared capability exists.
16. Keep local runtime inside its owning module.
17. Promote runtime to root level only when runtime responsibility spans modules.
18. Identify multi-module workflows.
19. Assign workflows to the feature that owns the outcome or create a meaningful workflow module.
20. Identify legitimate public integration events.
21. Separate public events from internal domain events.
22. Eliminate cyclic module dependencies.
23. Define local transaction behavior.
24. Define workflow recovery behavior where partial failure matters.
25. Add workflow persistence where resumability or compensation requires it.
26. Add structural enforcement where it protects meaningful boundaries.
27. Remove unnecessary abstractions, folders, layers, and ceremony.
28. Run build, architecture tests, unit tests, and integration tests.
29. Re-evaluate the resulting structure based on developer readability and actual ownership.

## Deliverables

For a **design**, produce:

* module map with the capability each module owns
* public contract list per module
* shared DTO list with the owning module for each — or an explicit "none"
* dependency graph, verified acyclic
* runtime placement (module-local vs. shared)
* cross-module workflow plan with transaction and partial-failure handling
* enforcement plan (which rules are automated, which remain review concerns)

For a **refactor**, produce in addition:

* current vs. target ownership map
* inventory of boundary violations with file evidence
* migration order — smallest useful cut first, behavior preserved
* contracts that must be introduced before internals can move
* architecture tests, with a frozen baseline if legacy violations are numerous
* verification steps (build, tests, architecture tests)

---

# Quick Decisions

| Situation | Default |
|---|---|
| Only one module uses it | Keep it local. |
| Another module needs behavior | Expose a public contract. |
| Another module needs data | Expose boundary data; never expose entities or repositories. |
| A type crosses a boundary | Move it to `shared/<owner>/` only when a real consumer exists. |
| A worker serves one module | Keep it in `module/runtime/`. |
| Runtime hosts several modules | Root `runtime/` is appropriate. |
| Only one module uses a technology | Keep the integration local. |
| Several modules need the same cohesive capability | Extract a technical module. |
| A workflow spans modules | Let the module owning the outcome orchestrate. |
| The caller needs an immediate result | Use a synchronous contract. |
| Others react to a completed fact | Publish a public integration event. |
| Partial failure is possible | Define retry, compensation, idempotency, or resumability. |
| A cycle appears | Reassign ownership or introduce a workflow module — not runtime indirection. |

Detailed rules for workflows, events, data ownership, transactions, and cycles are in `references/orchestration-data-transactions.md`.

---

# Reference Map

| Reference | Read when |
|---|---|
| `references/module-boundaries.md` | module layout, public contracts, shared DTOs, internal module architecture |
| `references/runtime-and-technical.md` | runtime placement, composition root, technical capability modules |
| `references/orchestration-data-transactions.md` | cross-module workflows, events, data ownership, transactions, cycles |
| `references/enforcement.md` | ArchUnit template, hard structural rules, tooling per stack |
| `references/review-checklist.md` | performing or reporting an architecture review |
| `references/language-mappings.md` | translating the architecture to Java, C#, NestJS, or Go |
| `references/decision-heuristics.md` | longer-form heuristics for ambiguous boundary decisions |
| `references/architectural-intent.md` | the full favors/avoids statement |

---

# Core Mental Model

Think of each module as a small application inside the larger system.

A module:

```text
owns its behavior
owns its domain
owns its data
owns its persistence
owns its transactions
owns its local runtime
owns its local technical implementation
hides its internals
publishes only what others genuinely need
```

By default:

```text
keep it local
```

When a responsibility genuinely crosses module boundaries:

```text
promote it intentionally
```

For shared boundary data:

```text
local model
    ↓ cross-module need
shared/<owner>/
```

For runtime:

```text
module/runtime
    ↓ shared execution responsibility
root/runtime
```

For technical capabilities:

```text
module-local implementation
    ↓ genuine reusable capability
shared technical module
```

For workflows:

```text
Feature modules own business state.
Orchestration modules own workflow state.
Public contracts express synchronous capabilities.
Public events express completed facts.
Shared DTOs express intentionally shared boundary data.
Runtime follows ownership.
```

The architecture does not require maximum isolation, maximum abstraction, or maximum folder depth.

The primary objective is to produce a system where:

* changes remain local
* ownership remains obvious
* dependencies remain visible
* implementation details remain replaceable
* business capabilities remain understandable
* shared concepts are intentionally shared
* runtime ownership remains clear
* cross-module workflows remain explicit
* data ownership remains enforceable
* failures can be recovered deliberately
* developers can understand the filesystem without first studying an architecture diagram
* structure grows because the system needs it
* architectural boundaries survive growth without becoming a burden

The shortest form of the architecture is:

> **Local first.**

> **Own what you use.**

> **Share only what is actually shared.**

> **Runtime follows ownership.**

> **Promote outward only when responsibility crosses a module boundary.**

> **Avoid module bleeding.**
