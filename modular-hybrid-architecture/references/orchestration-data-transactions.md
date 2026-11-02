# Orchestration, Data, and Transactions

> Part of the Modular Hybrid Architecture skill. Read this when designing cross-module workflows, events, data ownership, transaction boundaries, or the module dependency graph.

## Cross-Module Orchestration

Cross-module orchestration belongs to the module that owns the business outcome.

Example:

```text
Checkout
  ├─ Customers
  ├─ Inventory
  ├─ Payments
  └─ Orders
```

An orchestrating module may call multiple modules through their public contracts.

Example:

```java
class CheckoutService implements Checkout {

    private final InventoryReservation inventory;
    private final PaymentAuthorization payments;
    private final OrderCreation orders;

    // workflow orchestration
}
```

The orchestrator coordinates the workflow.

It does not gain ownership of participating modules' business state.

---

## Orchestration Rules

1. Business orchestration must live inside a feature or orchestration module.
2. The module that owns the business outcome owns the orchestration.
3. Cross-module calls must use public module contracts.
4. Runtime performs composition only and must not become the orchestrator.
5. Do not create orchestration modules merely to make dependency graphs look cleaner.
6. Create a dedicated orchestration module when the workflow itself represents a meaningful business capability.
7. High cross-module dependency fan-out is an architectural review signal, not automatically a violation.
8. A module must never directly access another module's persistence to implement orchestration.
9. An orchestration module coordinates behavior but does not gain ownership of participating modules' data.
10. Workflow state may belong to the orchestrating module when required.

Examples of legitimate workflow capabilities may include:

```text
Checkout
CustomerOnboarding
Fulfillment
Settlement
SubscriptionRenewal
```

---

## Public and Internal Events

Events are divided into:

```text
Public integration events
Internal domain events
```

Public integration events are part of the owning module's public API.

Internal domain events remain private implementation details.

Example:

```text
orders/
  OrderEvents.java

  services/
    domain/
      events/
        InternalOrderValidated.java
```

---

## Event Rules

1. Cross-module events must be intentionally public.
2. Internal domain events must never be consumed outside the owning module.
3. Public events represent facts that have already occurred.
4. Public events should not be commands disguised as events.
5. Events must not be introduced merely to hide cyclic dependencies.
6. Use synchronous contracts when the caller requires an immediate result.
7. Use public events when other modules may react independently to a completed fact.
8. Public events form part of the module's compatibility surface.
9. Event payloads should contain only the information deliberately required by consumers.
10. Generic event transport may be shared, but event meaning remains owned by the publishing business module.

Prefer:

```text
OrderPlaced
PaymentAuthorized
CustomerRegistered
InventoryReserved
```

over:

```text
SendInvoice
ReserveInventory
NotifyCustomer
CreateShipment
```

Useful mental distinction:

```text
Contract call = do something / give me a result

Event = something has happened
```

---

## Data Ownership

Each module exclusively owns its business data.

Example:

```text
Orders     → order state
Payments   → payment state
Inventory  → inventory state
Customers  → customer state
```

Only the owning module may directly mutate or query its internal persistence representation.

No other module may directly access:

```text
tables
entities
repositories
persistence managers
internal database structures
```

owned by another module.

Core rule:

> Same database does not mean shared ownership.

---

## Data Ownership Rules

1. A module owns and mutates its own persistent state.
2. Other modules interact with that state through public contracts or public events.
3. No module may directly use another module's repository.
4. No module may directly modify another module's database representation.
5. Read access must also respect module boundaries.
6. Internal persistence structures may change without requiring consumers to change.
7. Shared DTOs do not imply shared data ownership.
8. A module must not query another module's tables directly merely because they live in the same physical database.
9. Data ownership is logical ownership, not physical storage placement.
10. If multiple modules require the same business information, the owning module remains authoritative.

---

## Transactions

Each module owns its own local transaction boundaries.

There is no assumed global transaction across several modules.

Example:

```text
Checkout
   ↓
Inventory.reserve()    → Inventory transaction
   ↓
Payments.authorize()   → Payments transaction
   ↓
Orders.create()        → Orders transaction
```

The cross-module workflow must not assume that all operations can be rolled back atomically together.

---

## Transaction Rules

1. Each module owns its own local transactions.
2. A module transaction may mutate only data owned by that module.
3. Cross-module workflows execute through public contracts.
4. Cross-module orchestration must not assume global atomic rollback.
5. Partial failure must be explicitly considered where correctness requires it.
6. Recovery may use compensation, retry, idempotency, resumable workflow state, or eventual consistency.
7. External systems are never assumed to participate atomically in a local module transaction.
8. Persistence code must never cross module ownership boundaries to create a larger transaction.
9. A module should leave its own state consistent when its public operation completes.
10. Cross-module consistency is a workflow concern rather than a shared database transaction concern.

Core rule:

> Modules own data consistency.

> Orchestration owns workflow consistency.

---

## Workflow State

An orchestration module may persist workflow-specific state.

Example:

```text
checkout/
  Checkout.java

  services/
    CheckoutService.java

    persistence/
      CheckoutWorkflowEntity.java
      CheckoutWorkflowRepository.java
```

Workflow state may contain:

```text
workflowId
status
currentStep
inventoryReserved
paymentAuthorized
retryCount
lastCompletedStep
```

---

## Workflow Persistence Rules

1. An orchestration module may persist state required for coordination.
2. Workflow state may support recovery, retry, compensation, and resumability.
3. Workflow persistence must not become the authoritative store for another module's business data.
4. Orchestration modules must not duplicate entire participating domain models.
5. Identifiers and workflow-specific snapshots are acceptable where coordination requires them.
6. Workflow state should describe process progress rather than reproduce feature state.
7. Long-running workflows should be recoverable without requiring global transactions.
8. Compensation behavior should be explicit when operations cannot simply be retried.

Core distinction:

> Feature modules own business state.

> Orchestration modules own workflow state.

---

## Module Dependency Graph

The module dependency graph must remain acyclic.

Not allowed:

```text
Orders → Payments
Payments → Orders
```

Also not allowed:

```text
Orders → Customers
Customers → Pricing
Pricing → Orders
```

Instead:

```text
Checkout → Orders
Checkout → Payments
```

may be appropriate when Checkout owns the multi-module workflow.

Acyclicity applies to all modules, including shared technical capability modules.

---

## Cycle Rules

1. Cyclic module dependencies are forbidden.
2. If modules require mutual coordination, determine who owns the resulting business outcome.
3. Move coordination into the appropriate owning feature or workflow module.
4. Public events may support legitimate reactions but must not merely disguise a dependency cycle.
5. Repeated cycles are evidence that module ownership or boundaries may need reconsideration.
6. The module dependency graph should be understandable without inspecting implementation details.
7. Root runtime must not be used as an intermediary to hide cycles.
