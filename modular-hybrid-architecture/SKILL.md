# Modular Hybrid Architecture Skill — v1.1

## Purpose

Use this skill to design or refactor applications into a modular monolith that combines:

* feature-module ownership
* explicit public module contracts
* hidden module implementation
* internal clean architecture principles where they add value
* pragmatic service-oriented orchestration without excessive layering
* strong data ownership and explicit workflow coordination

The architecture prioritizes **module boundaries, ownership, locality, and controlled dependencies** over architectural ceremony.

---

## Core Principles

1. Organize by feature/domain capability, not horizontal technical layers.
2. Each module owns its business logic, domain models, persistence, and data.
3. A module root represents the module's complete public API surface.
4. Other modules may depend only on public contracts and public events located in the target module root.
5. No module may import another module's internal implementation.
6. Persistence entities and internal domain models must never leak outside the owning module.
7. Shared DTOs may be used as boundary/transport types, but must not become a shared domain model.
8. Infrastructure contains reusable technical capabilities only and must not contain feature business logic.
9. Cross-module wiring happens only in the composition root.
10. Business orchestration never belongs in the composition root or infrastructure.
11. Direct cyclic dependencies between modules are forbidden.
12. Each module owns its own data consistency and local transactions.
13. Cross-module workflows must explicitly handle partial failure where required.

---

# Module Public API

The module root represents the complete public API surface of the module.

A module may expose multiple public contracts when they represent distinct, cohesive business capabilities.

Example:

```text
orders/
  Orders.java
  OrderQueries.java
  OrderAdministration.java
  OrderEvents.java

  endpoint/

  services/
    OrdersService.java
    OrderQueriesService.java
    OrderAdministrationService.java

    domain/

    persistence/
```

Other modules may import:

```java
import orders.Orders;
import orders.OrderQueries;
```

They may never import:

```java
import orders.services.OrdersService;
import orders.services.persistence.OrderRepository;
import orders.services.domain.Order;
```

---

## Public Contract Rules

1. Module-root contracts are the only synchronous cross-module entry points.
2. Public contracts should represent cohesive business capabilities.
3. Split large contracts when they become conceptually broad.
4. Do not create one interface per individual method or use case.
5. Do not expose repositories, mappers, factories, validators, managers, or implementation abstractions through the module root.
6. Public contracts should expose behavior rather than internal implementation details.
7. Public contracts must never expose persistence entities or internal domain models.
8. Public contract implementations live inside the module's `services` package.

Prefer:

```text
Orders
OrderQueries
OrderAdministration
```

over:

```text
CreateOrder
UpdateOrder
DeleteOrder
GetOrder
FindOrder
```

unless those concepts genuinely represent stable business capabilities.

---

# Shared DTOs

Shared DTOs are allowed outside feature modules.

Example:

```text
shared/
  CustomerDto.java
  OrderDto.java
  MoneyDto.java
```

Shared DTOs exist only as boundary or transport representations.

They must not become the application's shared domain model.

A module may internally maintain separate representations:

```text
CustomerDto
    ↕

Customer domain model
    ↕

CustomerEntity
```

## Shared DTO Rules

1. Shared DTOs may be used by public module contracts.
2. Shared DTOs may cross module boundaries.
3. Shared DTOs must contain data, not module-specific business behavior.
4. Shared DTOs must not replace internal domain models where business invariants or domain behavior exist.
5. Persistence entities must never be placed in shared.
6. A shared DTO must not give another module ownership over the originating module's state.

---

# Standard Module Layout

```text
<module>/

  <PublicCapability>.java
  <PublicCapability>.java
  <PublicEvents>.java

  endpoint/

  services/
    <CapabilityImplementation>.java

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

The root should remain intentionally small.

Every type placed directly in the module root must represent something another module is legitimately allowed to consume.

---

# Infrastructure Layout

```text
infrastructure/
  logging/
  persistence/
  annotations/
  messaging/
  modules/
```

Infrastructure may provide technical capabilities such as:

* database configuration
* logging
* messaging
* serialization
* HTTP infrastructure
* framework configuration
* dependency wiring

Infrastructure must not contain feature-specific business behavior.

---

# Internal Module Architecture

Each module may internally use clean architecture principles while remaining pragmatic and lightweight.

The module boundary is more important than strict internal layering.

Inside the module:

* domain logic should remain independent from framework and persistence concerns
* persistence should adapt data storage to the module's needs
* services coordinate internal domain logic
* endpoints adapt external requests into module operations

Avoid:

* unnecessary abstraction layers
* command-handler explosion
* repository interfaces with no meaningful boundary value
* one-class-per-operation ceremony
* abstraction introduced only to satisfy a pattern

Prefer simple coordination where the dependency direction and ownership remain clear.

---

# Internal Dependency Rules

1. `endpoint` may call internal services or public-contract implementations.
2. Internal services may depend on domain logic and module-private abstractions.
3. Domain logic must not depend on endpoint, persistence, frameworks, infrastructure, or another module's internals.
4. Persistence may depend on internal domain representations where mapping is required.
5. Persistence entities remain private to the owning module.
6. Cross-module calls may only target public module-root contracts.
7. Infrastructure may provide technical capabilities but must not depend on feature internals.
8. Public contract implementations may coordinate internal services and domain behavior.

Conceptually:

```text
Endpoint
   ↓
Application / Facade Services
   ↓
Domain

Persistence adapters
   ↓
Domain
```

Persistence must not become a dependency of the domain.

---

# Cross-Module Orchestration

Cross-module orchestration belongs to the module that owns the business outcome.

Example:

```text
Checkout
  ├─ Customers
  ├─ Inventory
  ├─ Payments
  └─ Orders
```

An orchestrating module may call multiple modules through their public root contracts.

Example:

```java
class CheckoutService implements Checkout {

    private final InventoryReservation inventory;
    private final PaymentAuthorization payments;
    private final OrderCreation orders;

    // orchestration
}
```

## Orchestration Rules

1. Business orchestration must live inside a feature or orchestration module.
2. The module that owns the business outcome owns the orchestration.
3. Cross-module calls must use public module-root contracts.
4. Composition root performs wiring only and must never contain business orchestration.
5. Do not create orchestration modules merely to make dependency graphs look cleaner.
6. Create a dedicated orchestration module when the workflow itself represents a meaningful business capability.
7. High cross-module dependency fan-out is an architectural review signal, not automatically a violation.
8. A module must never directly access another module's persistence to implement orchestration.

Examples of legitimate orchestration capabilities may include:

```text
Checkout
CustomerOnboarding
Fulfillment
Settlement
```

A name such as:

```text
OrderCoordinatorManager
```

may indicate that ownership is unclear and should be reviewed.

---

# Public and Internal Events

Events are divided into two categories:

```text
Public integration events
Internal domain events
```

Public integration events are part of the module's public API.

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

## Event Rules

1. Cross-module events must be explicitly declared as part of the module root API.
2. Internal domain events must never be consumed outside the owning module.
3. Public events represent facts that have already occurred.
4. Public events should not be commands disguised as events.
5. Events must not be introduced solely to hide cyclic dependencies.
6. Use synchronous public contracts when the caller requires an immediate result.
7. Use public events when other modules may react independently to a completed business fact.

Prefer:

```text
OrderPlaced
PaymentAuthorized
CustomerRegistered
```

over:

```text
SendInvoice
ReserveInventory
NotifyCustomer
```

The first group represents facts.

The second group represents commands.

---

# Data Ownership

Each module exclusively owns its data.

Only the owning module may mutate that data.

Example:

```text
Orders     → owns order state
Payments   → owns payment state
Inventory  → owns inventory state
Customers  → owns customer state
```

No other module may directly modify those tables, entities, repositories, or persistence structures.

## Data Ownership Rules

1. A module owns and mutates its own persistent state.
2. Other modules interact with that state only through public contracts or public events.
3. No module may directly use another module's repository.
4. No module may directly update another module's database representation.
5. Internal persistence structure may change without requiring consumers to change.
6. Shared DTOs do not imply shared ownership.

---

# Transactions

Each module owns its own local transaction boundaries.

There is no assumed global transaction spanning multiple modules.

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

The cross-module workflow must not assume that all operations can be atomically rolled back together.

## Transaction Rules

1. Each module owns its own local transactions.
2. A module transaction may mutate only data owned by that module.
3. Cross-module workflows execute through public contracts.
4. Cross-module orchestration must not assume global atomic rollback.
5. Partial failure must be explicitly considered where correctness requires it.
6. Recovery may use compensation, retry, idempotency, resumable workflow state, or eventual consistency.
7. External systems are never assumed to participate atomically in a module transaction.
8. Persistence code must never cross module ownership boundaries to create a larger transaction.

---

# Workflow State

An orchestration module may own persistence for the workflow itself.

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

Workflow state may contain information such as:

```text
workflowId
status
currentStep
inventoryReserved
paymentAuthorized
retryCount
lastCompletedStep
```

## Workflow Persistence Rules

1. An orchestration module may persist state required for coordination.
2. Workflow state may support recovery, retry, compensation, and resumability.
3. Workflow persistence must not become the authoritative store for another module's business data.
4. Orchestration modules must not duplicate entire domain models from participating modules.
5. References such as identifiers and workflow-specific snapshots are allowed where required for coordination.

The distinction is:

> Modules own business state.

> Orchestration modules own workflow state.

---

# Module Dependency Graph

Direct cyclic module dependencies are forbidden.

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

The module contract dependency graph should remain acyclic.

## Cycle Rules

1. Direct cyclic contract dependencies between modules are forbidden.
2. If two modules require mutual coordination, determine which module owns the business outcome.
3. Move multi-module coordination into the owning feature or an appropriate orchestration module.
4. Public events may support legitimate reactions but must not be used merely to disguise a dependency cycle.
5. Repeated dependency cycles are evidence that module boundaries or ownership may need reconsideration.

Example:

Instead of:

```text
Orders → Payments
Payments → Orders
```

prefer:

```text
Checkout → Orders
Checkout → Payments
```

where Checkout owns the workflow.

---

# Composition Root

Only the composition root may instantiate or wire implementations across module boundaries.

Example:

```text
infrastructure/
  modules/
    ModuleRegistry.java
```

The composition root may:

* instantiate module implementations
* connect public module contracts
* configure technical dependencies
* register adapters
* configure runtime infrastructure

It must not contain:

* business rules
* workflow logic
* domain decisions
* cross-module business orchestration

Example:

Allowed:

```java
Orders orders = new OrdersService(...);
Payments payments = new PaymentsService(...);

Checkout checkout =
    new CheckoutService(orders, payments);
```

Not allowed:

```java
payments.authorize(...);
orders.create(...);
notifications.send(...);
```

inside the composition root.

---

# Architecture Enforcement

Structural architecture rules should be automated where practical.

Semantic design decisions remain a code-review responsibility.

## Hard Structural Rules

These are candidates for automated enforcement:

1. Cross-module imports may target only public root contracts and public root events.
2. Imports of another module's `services` package are forbidden.
3. Imports of another module's domain internals are forbidden.
4. Imports of another module's persistence package are forbidden.
5. Persistence entities must not cross module boundaries.
6. Internal domain events must remain module-private.
7. Infrastructure must not depend on feature-module internals.
8. Direct cyclic module dependencies are forbidden.

These rules may be enforced using tools such as architectural tests where appropriate.

---

## Semantic Review Rules

The following should normally remain review concerns:

* whether a module owns the correct business capability
* whether an orchestration module is justified
* whether a public contract is too broad
* whether contracts have been split too aggressively
* whether a shared DTO has become a shared domain model
* whether an event represents a fact or a hidden command
* whether one module has excessive dependency fan-out
* whether workflow state has started duplicating domain ownership
* whether abstractions provide real architectural value

These require business and architectural context and should not be reduced blindly to mechanical rules.

---

# Refactor Workflow

1. Identify business capabilities and module boundaries.
2. Map existing cross-module dependencies.
3. Identify current ownership violations.
4. Define public module-root contracts.
5. Define shared DTO boundary types where required.
6. Move implementations behind module contracts.
7. Move domain logic into the owning feature module.
8. Move each module's persistence into its own `services/persistence`.
9. Remove cross-module persistence access.
10. Extract genuinely shared technical capabilities into `infrastructure`.
11. Move cross-module wiring into the composition root.
12. Identify multi-module workflows.
13. Assign each workflow to the feature that owns the business outcome or create an explicit orchestration module.
14. Identify legitimate public integration events.
15. Separate public events from internal domain events.
16. Identify cyclic module dependencies and eliminate them.
17. Define transaction and recovery behavior for cross-module workflows.
18. Add architecture enforcement where useful.
19. Remove unnecessary abstractions and architectural ceremony.
20. Run build, architecture tests, unit tests, and integration tests.

---

# Decision Heuristics

## Ownership

If code expresses a business capability:

> Keep it inside the owning feature module.

If code is technical and reusable without understanding any business module:

> Place it in infrastructure.

If another module needs behavior:

> Expose it through a public root contract.

If another module needs data:

> Expose boundary data through the owning module's contract rather than sharing internal models.

---

## Contracts

If a public contract becomes too broad:

> Split it by cohesive business capability.

Do not split simply because the file has become large.

Prefer:

```text
Orders
OrderQueries
OrderAdministration
```

over a separate interface for every operation.

---

## DTOs

If a type exists only to move data across boundaries:

> A shared DTO may be appropriate.

If the type contains business invariants or behavior:

> It belongs inside the owning module's domain.

---

## Orchestration

If a workflow clearly produces an outcome owned by one module:

> That module should orchestrate the workflow.

If the workflow itself represents an independent business capability:

> Create an orchestration module.

If orchestration exists only to reduce visible dependencies:

> Reconsider the design.

---

## Events

If another module must immediately return a result:

> Use a synchronous root contract.

If other modules should independently react to something that already happened:

> Publish a public integration event.

If an event says what another module should do:

> It is probably a command and should be reconsidered.

---

## Transactions

If an operation changes only one module's state:

> That module owns the transaction.

If a workflow spans multiple modules:

> Each module commits its own state.

If partial failure matters:

> The orchestrator must define retry, compensation, idempotency, resumability, or another explicit recovery strategy.

---

## Persistence

If code accesses feature-owned business data:

> It belongs to the owning module.

If code provides technical persistence infrastructure without knowing business semantics:

> It may belong in infrastructure.

---

## Abstraction

Create an abstraction only when it:

* protects a meaningful boundary
* enables genuine substitution
* clarifies ownership
* reduces meaningful complexity

Do not create abstractions merely to satisfy architectural convention.

---

# Language Mapping

## Java

Use:

* packages as module boundaries
* public contracts in module roots
* package-private/internal implementations where practical
* registry or dependency-injection composition root
* architecture tests such as ArchUnit where appropriate

## C#

Use:

* namespaces or projects as module boundaries
* public contract namespaces
* internal implementations
* dependency injection for composition
* architecture tests where useful

## Node / NestJS

Use:

* feature modules
* exported providers/contracts
* strict module exports
* private internal providers
* explicit public events

## Go

Use:

* package boundaries
* exported module APIs
* internal packages
* explicit dependency composition
* narrow capability-oriented interfaces

---

# Architectural Intent

This architecture intentionally favors:

* strong feature ownership
* explicit module boundaries
* hidden implementation details
* small and understandable public surfaces
* module-owned persistence
* data ownership
* controlled cross-module interaction
* acyclic dependencies
* explicit orchestration
* recoverable workflows
* feature-oriented locality
* pragmatic internal architecture
* architectural clarity over architectural purity

The architecture intentionally avoids:

* global horizontal business layers
* shared persistence models
* cross-module repository access
* giant universal service interfaces
* interface-per-method ceremony
* hidden business orchestration in infrastructure
* global transactional assumptions
* uncontrolled event coupling
* circular module dependencies
* abstraction for abstraction's sake

---

# Core Mental Model

Think of each module as a small application inside the larger application.

Each module:

```text
owns its behavior
owns its domain
owns its data
owns its transactions
hides its implementation
publishes explicit capabilities
publishes explicit integration events
```

Other modules may know only what the module deliberately exposes.

For workflows spanning multiple modules:

```text
Feature modules own business state.

Orchestration modules own workflow state.

Public contracts express synchronous capabilities.

Public events express completed facts.

The composition root only connects the system.
```

The primary architectural objective is not strict adherence to a named pattern.

The objective is to produce a system where:

* changes remain local
* module ownership is clear
* dependencies are visible
* implementation details remain replaceable
* business capabilities remain understandable
* cross-module workflows remain explicit
* architectural boundaries survive growth
