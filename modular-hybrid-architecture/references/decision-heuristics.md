# Decision Heuristics

> Part of the Modular Hybrid Architecture skill. Read this when a boundary decision is genuinely ambiguous and you want the longer form of the decision rules.

## Local First

If only one module needs something:

> Keep it inside that module.

If another module genuinely needs it:

> Consider promoting it outward.

If something might theoretically be reused later:

> Keep it local until that reuse actually exists.

When uncertain:

> Keep it local.

---

## Shared

If a DTO is consumed only by its owning module:

> Keep it inside that module.

If another module legitimately consumes it:

> It may move to `shared/<owner>/`.

If nobody can identify the DTO owner:

> Reconsider the DTO or module boundary.

If the type contains business invariants or behavior:

> It is probably not a DTO and belongs in the owning module's domain.

---

## Runtime

If runtime behavior belongs to one module:

> Keep runtime inside that module.

If a worker is standalone but belongs to Orders:

```text
orders/runtime/worker/
```

is correct.

If runtime responsibility genuinely spans several modules:

> A root-level runtime may be appropriate.

Core rule:

> Standalone does not mean global.

---

## Technical Behavior

If technical code understands one feature:

> Keep it inside that feature module.

If only Orders uses Kafka:

> Kafka integration remains inside Orders.

If several modules genuinely require a cohesive generic messaging capability:

> Consider extracting a Messaging module.

Do not create technical modules merely because code uses a particular technology.

---

## Ownership

If code expresses or implements a business capability:

> Keep it inside the owning feature module.

If another module needs behavior:

> Expose it through a public contract.

If another module needs data:

> Expose intentional boundary data without sharing internal domain representations.

If multiple modules need the same business information:

> Ownership remains with the source module.

---

## Contracts

If a public contract becomes conceptually broad:

> Split it by cohesive capability.

Do not split simply because a file becomes large.

Prefer:

```text
Orders
OrderQueries
OrderAdministration
```

over an interface for every operation.

---

## Orchestration

If a workflow clearly produces an outcome owned by one module:

> That module should orchestrate it.

If the workflow itself represents an independent business capability:

> Create a workflow module.

If orchestration exists only to make dependency arrows look cleaner:

> Reconsider the design.

If orchestration appears in root runtime:

> Move it into the module that owns the business outcome.

---

## Events

If another module requires an immediate result:

> Use a synchronous contract.

If other modules may independently react to a completed fact:

> Publish a public integration event.

If an event describes what another module should do:

> It is probably a command disguised as an event.

If an event exists only to hide a cycle:

> Reconsider the module relationship.

---

## Transactions

If an operation changes one module's state:

> That module owns the transaction.

If a workflow spans multiple modules:

> Each module commits its own state.

If partial failure matters:

> Define retry, compensation, idempotency, resumability, or another explicit recovery strategy.

Do not create a global transaction by crossing module persistence boundaries.

---

## Persistence

If persistence code understands feature-owned business data:

> It belongs inside the owning feature module.

If another module needs read access:

> Use the owning module's public API.

Do not query another module's tables simply because the physical database is shared.

---

## Structure

If a folder has no meaningful responsibility:

> Do not create it.

If an internal structure adds clarity:

> Use it.

If structure exists only because the architectural example shows it:

> Remove it.

Core rule:

> Architecture should organize complexity, not manufacture it.

---

## Abstraction

Create an abstraction only when it:

* protects a meaningful boundary
* enables genuine substitution
* clarifies ownership
* reduces meaningful complexity

Do not create abstractions merely to satisfy convention.
