# Architecture Review Checklist

> Part of the Modular Hybrid Architecture skill. Use this to review an existing codebase or a proposed design. The checklist makes semantic rules repeatable; it does not replace judgment.

## How to use

1. Review one module at a time, then review the system as a whole.
2. Record evidence — file paths and package names, not impressions.
3. Distinguish **structural** findings (mechanically checkable) from **semantic** findings (judgment).
4. Report findings with a severity (see below). Do not rewrite the architecture in the review; produce an actionable list first.
5. Prefer a small number of high-value findings over a long list of cosmetic ones.

### Severity

| Severity | Meaning |
|---|---|
| **Critical** | Ownership is violated in a way that blocks correct change or data safety (cross-module persistence, cycle, shared entity). |
| **High** | Boundary erosion that will spread (internal imports, command-as-event, runtime orchestration). |
| **Medium** | Premature promotion, oversized public contract, duplicated workflow state. |
| **Low** | Naming, folder clarity, documentation, structural polish. |

---

## 1. Module Inventory

Map the system before judging it:

| Module | Business capability | Public types | Owns data? | Runtime? |
|---|---|---|---|---|
| | | | | |

Questions:

- [ ] Does every module name a capability, not a technical layer?
- [ ] Is there a module that exists only to hold code used elsewhere (`utils`, `common-services`)?
- [ ] Does each module have a visible public surface at its root?
- [ ] Can a newcomer tell from the filesystem what each module owns?

---

## 2. Ownership

- [ ] Every business capability has exactly one owning module.
- [ ] Code sits in the module that owns the behavior, not the module that calls it.
- [ ] No module implements another module's business rules.
- [ ] No "ownerless" business logic lives in shared folders.
- [ ] Feature code has not been moved outward merely because it uses a framework or technology.

---

## 3. Public Surface

- [ ] Cross-module calls touch only public contracts and public events.
- [ ] No imports of another module's `services`, `domain`, `persistence`, `models`, or `runtime`.
- [ ] Public contracts expose behavior, not repositories, mappers, entities, or internal managers.
- [ ] Contracts are split by capability, not one interface per method.
- [ ] No single contract has become a 100-method god interface.
- [ ] Public API size is proportional to what consumers actually need.

---

## 4. Shared DTOs

- [ ] `shared/` exists only because a type is genuinely consumed outside its owner.
- [ ] Every type under `shared/` is under `shared/<owner>/` (except a deliberately small `shared/common/`).
- [ ] No persistence entity or internal domain model under `shared/`.
- [ ] Shared DTOs carry data, not business invariants or behavior.
- [ ] Consumers that need local behavior map the DTO into their own type.
- [ ] No DTO was promoted "because it might be reused later".

---

## 5. Persistence and Data

- [ ] Each module accesses only its own repositories, entities, and tables.
- [ ] No cross-module joins or queries, including read-only ones.
- [ ] Persistence entities never appear in another module's signatures.
- [ ] Shared physical database is not treated as shared ownership.
- [ ] Schema changes inside one module do not force changes in consumers.
- [ ] The owning module is authoritative when several modules need the same data.

---

## 6. Runtime and Composition

- [ ] Module-specific runtime lives inside that module.
- [ ] Root runtime exists only because it hosts/composes multiple modules.
- [ ] Root runtime contains wiring, not workflows.
- [ ] No module depends on root runtime.
- [ ] A standalone worker is not automatically placed in root runtime.
- [ ] Composition root does not call business operations to "start" a workflow.

---

## 7. Technical Capabilities

- [ ] Database, messaging, HTTP, cache, and logging code stays local until shared use is real.
- [ ] Extracted technical modules represent a cohesive capability, not a utility drawer.
- [ ] Technical modules do not know business types (`Order`, `Customer`, ...).
- [ ] Technical modules expose contracts and hide implementation.
- [ ] Shared implementation similarity alone did not trigger extraction.

---

## 8. Cross-Module Workflows

- [ ] The orchestrator is the module that owns the business outcome, or a real workflow module.
- [ ] Orchestration is not hidden in runtime or a controller/endpoint.
- [ ] Every cross-module call goes through a public contract.
- [ ] No module reaches into another module's data to complete a workflow.
- [ ] High fan-out is explained by a genuine business capability, not convenience.
- [ ] Workflow state describes progress, not a copy of feature state.
- [ ] Partial failure has an explicit strategy: retry, compensation, idempotency, resumability, or accepted eventual consistency.
- [ ] No global transaction spans module persistence boundaries.

---

## 9. Events

- [ ] Cross-module events are intentionally public; internal domain events stay private.
- [ ] Events describe facts in the past tense, not commands.
- [ ] An event does not exist only to hide a dependency cycle.
- [ ] Payloads contain only what consumers deliberately need.
- [ ] Synchronous contracts are used where the caller needs an immediate result.
- [ ] Event meaning is owned by the publishing business module, even when transport is shared.

---

## 10. Dependencies

- [ ] The module graph is acyclic.
- [ ] Cycles were resolved by reassigning ownership or adding a workflow module — not by events or runtime indirection.
- [ ] The graph is explainable without reading implementation details.
- [ ] Root runtime is not used as a cycle-breaking intermediary.

---

## 11. Structure and Readability

- [ ] Folders exist because responsibilities exist, not because a template says so.
- [ ] Empty or ceremonial layers have been removed.
- [ ] Internal structure is as simple as the module allows.
- [ ] Abstractions protect a boundary, enable substitution, or reduce real complexity.
- [ ] The filesystem answers: where does this belong, who owns it, what may I consume?

---

## 12. Promotion Audit (Module Bleeding)

For each type outside a module, ask:

- [ ] Who owns it?
- [ ] Which modules consume it today? (Not tomorrow.)
- [ ] Could it return to the owning module without breaking a real consumer?
- [ ] Is it in `shared`/`common`/root runtime only because it "looks architectural"?

Any "yes" to the last question is module bleeding and should be fixed.

---

## Report Template

```markdown
## Architecture review — <system / PR>

### Module map
<table or graph>

### Findings
| # | Severity | Location | Finding | Recommended action |
|---|---|---|---|---|
| 1 | High | orders/services/... | Payments repository imported by Orders | Expose via Payments public contract |

### Boundary violations
- Cross-module persistence: ...
- Internal imports: ...
- Cycles: ...

### Promotion / bleeding candidates
- ...

### Suggested enforcement
- ArchUnit rule: ...
- dependency-cruiser rule: ...

### Open questions
- ...
```
