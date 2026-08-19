# Modular Hybrid Architecture Skill — v1.2

## Purpose

Use this skill to design or refactor applications into a modular monolith that combines:

* feature-module ownership
* explicit public module contracts
* hidden module implementation
* internal clean architecture principles where they add value
* pragmatic service-oriented orchestration without excessive layering
* strong data ownership and explicit workflow coordination

The architecture prioritizes **module boundaries, ownership, locality, controlled dependencies, and maintainability at scale** over architectural ceremony.

---

## Core Principles

1. Organize by feature or domain capability, not horizontal technical layers.
2. Each module owns its business logic, domain models, persistence, data, and local transactions.
3. A module root represents the module's complete public API surface.
4. A module root may contain multiple public contracts when they represent cohesive business capabilities.
5. Other modules may depend only on public contracts and public events located in the target module root.
6. No module may import another module's internal implementation.
7. Persistence entities and internal domain models must never leak outside the owning module.
8. Shared DTOs may cross module boundaries, but every business DTO must have exactly one owning module.
9. Shared DTOs are transport and boundary types only and must not become a shared domain model.
10. Infrastructure contains reusable technical capabilities only and must not contain feature business logic.
11. Cross-module wiring happens only in the composition root.
12. Business orchestration never belongs in the composition root or infrastructure.
13. Direct cyclic module dependencies are forbidden.
14. Each module owns its own data consistency and local transactions.
15. Cross-module workflows must explicitly handle partial failure where required.
16. Orchestration modules may own workflow state but must never become owners of participating modules' business data.

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
      models/
      rules/
      events/

    persistence/
      entities/
      repositories/
      managers/
      mappers/
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

The root directory is therefore not merely organizational.

It defines the module's externally visible boundary.

---

# Public Contract Rules

1. Module-root contracts are the only synchronous cross-module entry points.
2. Public contracts should represent cohesive business capabilities.
3. Split large contracts when they become conceptually broad.
4. Do not create one interface per individual method or use case.
5. Do not expose repositories, mappers, factories, validators, managers, or implementation abstractions through the module root.
6. Public contracts should expose behavior rather than internal implementation details.
7. Public contracts must never expose persistence entities or internal domain models.
8. Public contract implementations live inside the module's `services` package.
9. Root contracts should remain intentionally focused and understandable.
10. A large root API surface is an architectural review signal even if all rules are technically followed.

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

The goal is to avoid both extremes:

```text
one 150-method interface
```

and:

```text
150 one-method interfaces
```

Split by stable business capability, not by arbitrary operation count.

---

# Shared DTO Ownership

Shared DTOs are allowed outside feature modules, but every business DTO must belong to exactly one owning module.

Shared DTOs must therefore be organized by module ownership.

Example:

```text
shared/
  customers/
    CustomerDto.java
    CustomerSummaryDto.java

  orders/
    OrderDto.java
    OrderLineDto.java

  payments/
    PaymentDto.java
    PaymentStatusDto.java
```

The directory under `shared` identifies the module that owns the DTO contract.

For example:

```text
shared/customers/CustomerDto.java
```

means:

> `CustomerDto` is publicly consumable, but its semantics and evolution are owned by the `customers` module.

Other modules may consume the DTO, but they do not gain ownership of it.

---

# Shared DTO Rules

1. Every business DTO must belong to exactly one owning module.
2. Module-owned DTOs must be placed under:

```text
shared/<module>/
```

3. The owning module defines the DTO's meaning, structure, and evolution.
4. Other modules may consume the DTO but must not redefine its semantics.
5. Shared DTOs are boundary and transport types only.
6. Shared DTOs must not become the application's shared domain model.
7. Shared DTOs must not contain module-specific business behavior.
8. Persistence entities must never be placed in `shared`.
9. Internal domain models must never be placed in `shared`.
10. A shared DTO does not imply shared ownership of the underlying business state.
11. Consumers should convert shared DTOs into their own internal representation when business behavior or local invariants require it.
12. A DTO being used by many modules does not make it ownerless.
13. DTO ownership should remain visible directly in package or folder structure.

Conceptually:

```text
customers/
  services/
    domain/
      Customer.java

       ↓ mapped to

shared/
  customers/
    CustomerDto.java

       ↓ consumed by

orders/
  services/
    ...
```

Ownership remains:

```text
Customer domain state
        ↓
     Customers

CustomerDto contract
        ↓
     Customers

Consumer interpretation
        ↓
      Orders
```

---

# Avoid Unowned Shared Types

Avoid structures such as:

```text
shared/
  dto/
    CustomerDto.java
    OrderDto.java
    PaymentDto.java
```

because ownership becomes unclear.

Also avoid turning `shared/common` into a general dumping ground.

A small common area may exist for genuinely ownerless technical transport concepts:

```text
shared/
  common/
    PageDto.java
    ErrorDto.java
```

but it should remain intentionally small.

If a DTO represents a business concept, it should normally have an owning module.

Core rule:

> `shared` means publicly consumable data contracts.

It does not mean:

> data that belongs to everyone.

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

The module root should remain intentionally small.

Every type placed directly in the module root must represent something another module is legitimately allowed to consume.

The root must not contain:

```text
repositories
mappers
factories
validators
internal managers
persistence entities
internal domain models
implementation classes
```

unless one of those concepts genuinely forms part of the public business API, which should be rare.

---

# Infrastructure Layout

```text
infrastructure/
  logging/
  persistence/
  annotations/
  messaging/
  modules/
  configuration/
```

Infrastructure may provide reusable technical capabilities such as:

* database configuration
* logging
* messaging
* serialization
* HTTP infrastructure
* framework configuration
* dependency wiring
* technical adapters

Infrastructure must not contain feature-specific business behavior.

A useful test is:

> Could this code exist without knowing any business module?

If yes, it may belong in infrastructure.

If it understands business semantics, it probably belongs inside a feature module.

---

# Internal Module Architecture

Each module may internally use clean architecture principles while remaining pragmatic and lightweight.

The module boundary is more important than strict internal layering.

Inside the module:

* domain logic should remain independent from framework and persistence concerns
* persistence should adapt data storage to the module's needs
* services coordinate internal domain logic
* endpoints adapt external requests into module operations
* internal abstractions should exist only when they provide real value

Avoid:

* unnecessary abstraction layers
* command-handler explosion
* repository interfaces with no meaningful boundary value
* one-class-per-operation ceremony
* abstraction introduced only to satisfy a pattern
* framework-shaped domain models
* domain rules spread across unrelated layers

Prefer simple coordination where dependency direction and ownership remain clear.

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
9. Domain logic must not know how it is persisted.
10. Module internals may evolve freely as long as the public contracts remain compatible.

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

Persistence may know domain representations.

Domain must not know persistence.

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

The orchestrating module coordinates the workflow but does not own participating modules' business state.

---

# Orchestration Rules

1. Business orchestration must live inside a feature or orchestration module.
2. The module that owns the business outcome owns the orchestration.
3. Cross-module calls must use public module-root contracts.
4. Composition root performs wiring only and must never contain business orchestration.
5. Do not create orchestration modules merely to make dependency graphs look cleaner.
6. Create a dedicated orchestration module when the workflow itself represents a meaningful business capability.
7. High cross-module dependency fan-out is an architectural review signal, not automatically a violation.
8. A module must never directly access another module's persistence to implement orchestration.
9. An orchestration module coordinates behavior but does not gain ownership of participating modules' data.
10. A workflow module may depend on several feature contracts when that dependency reflects genuine business coordination.

Examples of legitimate orchestration capabilities may include:

```text
Checkout
CustomerOnboarding
Fulfillment
Settlement
SubscriptionRenewal
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

---

# Event Rules

1. Cross-module events must be explicitly declared as part of the module root API.
2. Internal domain events must never be consumed outside the owning module.
3. Public events represent facts that have already occurred.
4. Public events should not be commands disguised as events.
5. Events must not be introduced solely to hide cyclic dependencies.
6. Use synchronous public contracts when the caller requires an immediate result.
7. Use public events when other modules may react independently to a completed business fact.
8. Public events are part of the module's compatibility surface.
9. Event payloads should contain the minimum information required by consumers.
10. Consumers should not rely on internal module lifecycle details that were never intentionally published.

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

The first group represents facts.

The second group represents commands.

A useful mental distinction is:

```text
Contract call = do something / give me a result
Event         = something has happened
```

---

# Data Ownership

Each module exclusively owns its business data.

Only the owning module may mutate that data.

Example:

```text
Orders     → owns order state
Payments   → owns payment state
Inventory  → owns inventory state
Customers  → owns customer state
```

No other module may directly modify those tables, entities, repositories, or persistence structures.

---

# Data Ownership Rules

1. A module owns and mutates its own persistent state.
2. Other modules interact with that state only through public contracts or public events.
3. No module may directly use another module's repository.
4. No module may directly update another module's database representation.
5. Internal persistence structure may change without requiring consumers to change.
6. Shared DTOs do not imply shared ownership.
7. Read access must also respect module boundaries.
8. A module must not query another module's tables directly merely because they live in the same database.
9. Data ownership is logical ownership, not merely physical database placement.
10. If multiple modules require the same business information, the owning module remains authoritative.

Core rule:

> Same database does not mean shared ownership.

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

---

# Transaction Rules

1. Each module owns its own local transactions.
2. A module transaction may mutate only data owned by that module.
3. Cross-module workflows execute through public contracts.
4. Cross-module orchestration must not assume global atomic rollback.
5. Partial failure must be explicitly considered where correctness requires it.
6. Recovery may use compensation, retry, idempotency, resumable workflow state, or eventual consistency.
7. External systems are never assumed to participate atomically in a module transaction.
8. Persistence code must never cross module ownership boundaries to create a larger transaction.
9. A module must leave its own state consistent when its public operation completes.
10. Cross-module consistency is a workflow concern, not a shared database transaction concern.

Core rule:

> Modules own data consistency.

> Orchestration owns workflow consistency.

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

---

# Workflow Persistence Rules

1. An orchestration module may persist state required for coordination.
2. Workflow state may support recovery, retry, compensation, and resumability.
3. Workflow persistence must not become the authoritative store for another module's business data.
4. Orchestration modules must not duplicate entire domain models from participating modules.
5. References such as identifiers and workflow-specific snapshots are allowed where required for coordination.
6. Workflow state should describe progress through a process rather than reproduce participating modules' state.
7. Long-running workflows should be recoverable without requiring global transactions.
8. Compensation behavior should be explicit when operations cannot simply be retried.

The distinction is:

> Feature modules own business state.

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

---

# Cycle Rules

1. Direct cyclic contract dependencies between modules are forbidden.
2. If two modules require mutual coordination, determine which module owns the business outcome.
3. Move multi-module coordination into the owning feature or an appropriate orchestration module.
4. Public events may support legitimate reactions but must not be used merely to disguise a dependency cycle.
5. Repeated dependency cycles are evidence that module boundaries or ownership may need reconsideration.
6. The public module dependency graph should be understandable without inspecting internal implementation.
7. Acyclicity applies to module relationships, not merely package compiler rules.

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

Core rule:

> The composition root connects the system.

> It does not run the business.

---

# Architecture Enforcement

Structural architecture rules should be automated where practical.

Semantic design decisions remain a code-review responsibility.

---

# Hard Structural Rules

These are candidates for automated enforcement:

1. Cross-module imports may target only public root contracts and public root events.
2. Imports of another module's `services` package are forbidden.
3. Imports of another module's domain internals are forbidden.
4. Imports of another module's persistence package are forbidden.
5. Persistence entities must not cross module boundaries.
6. Internal domain events must remain module-private.
7. Infrastructure must not depend on feature-module internals.
8. Direct cyclic module dependencies are forbidden.
9. Module-owned DTOs should remain under the correct `shared/<module>/` ownership path.
10. Cross-module persistence access should fail architectural checks where it can be detected.

These rules may be enforced using tools such as architectural tests where appropriate.

For Java, tools such as ArchUnit may be suitable.

---

# Semantic Review Rules

The following should normally remain review concerns:

* whether a module owns the correct business capability
* whether an orchestration module is justified
* whether a public contract is too broad
* whether contracts have been split too aggressively
* whether a shared DTO has become a shared domain model
* whether DTO ownership is correct
* whether an event represents a fact or a hidden command
* whether one module has excessive dependency fan-out
* whether workflow state has started duplicating domain ownership
* whether abstractions provide real architectural value
* whether a workflow belongs in an existing module or deserves its own capability
* whether module boundaries still reflect the business after the system evolves

These require business and architectural context and should not be reduced blindly to mechanical rules.

---

# Refactor Workflow

1. Identify business capabilities and proposed module boundaries.
2. Map existing cross-module dependencies.
3. Identify current ownership violations.
4. Identify cross-module persistence access.
5. Define public module-root contracts.
6. Split overly broad contracts by cohesive business capability.
7. Define module-owned shared DTO boundary types under `shared/<module>/`.
8. Move implementations behind module contracts.
9. Move domain logic into the owning feature module.
10. Move each module's persistence into its own `services/persistence`.
11. Remove cross-module persistence access.
12. Extract genuinely shared technical capabilities into `infrastructure`.
13. Move cross-module wiring into the composition root.
14. Identify multi-module workflows.
15. Assign each workflow to the feature that owns the business outcome or create an explicit orchestration module.
16. Identify legitimate public integration events.
17. Separate public events from internal domain events.
18. Identify cyclic module dependencies and eliminate them.
19. Define local transaction behavior for each module.
20. Define recovery behavior for cross-module workflows.
21. Add workflow persistence where resumability or compensation requires it.
22. Add architecture enforcement where useful.
23. Remove unnecessary abstractions and architectural ceremony.
24. Run build, architecture tests, unit tests, and integration tests.
25. Re-evaluate module ownership after the refactor rather than assuming the initial boundaries were correct.

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

If multiple modules need the same data:

> That does not remove ownership from the source module.

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

A contract should reflect a stable business capability, not a technical implementation grouping.

---

## DTOs

If a type exists only to move data across boundaries:

> A shared DTO may be appropriate.

If the DTO belongs to Customers:

```text
shared/customers/
```

If it belongs to Payments:

```text
shared/payments/
```

If nobody can identify the owner:

> Reconsider the DTO or module boundary.

If the type contains business invariants or behavior:

> It is probably not a DTO and belongs inside the owning module's domain.

If a consumer begins adding business behavior directly to another module's DTO:

> Map it into a local model instead.

---

## Orchestration

If a workflow clearly produces an outcome owned by one module:

> That module should orchestrate the workflow.

If the workflow itself represents an independent business capability:

> Create an orchestration module.

If orchestration exists only to reduce visible dependencies:

> Reconsider the design.

If an orchestration module begins owning participating modules' state:

> The boundary has been violated.

---

## Events

If another module must immediately return a result:

> Use a synchronous root contract.

If other modules should independently react to something that already happened:

> Publish a public integration event.

If an event says what another module should do:

> It is probably a command and should be reconsidered.

If an event exists only to avoid showing a direct dependency:

> Reconsider the module relationship.

---

## Transactions

If an operation changes only one module's state:

> That module owns the transaction.

If a workflow spans multiple modules:

> Each module commits its own state.

If partial failure matters:

> The orchestrator must define retry, compensation, idempotency, resumability, or another explicit recovery strategy.

If a design requires direct rollback across several module databases or states:

> Reconsider the ownership model rather than creating an implicit global transaction.

---

## Persistence

If code accesses feature-owned business data:

> It belongs to the owning module.

If code provides technical persistence infrastructure without knowing business semantics:

> It may belong in infrastructure.

If another module needs read access:

> Use the owning module's public API instead of querying its persistence directly.

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
* module-owned DTO packages under `shared/<module>/`
* package-private or internal implementations where practical
* registry or dependency-injection composition root
* architecture tests such as ArchUnit where appropriate

## C#

Use:

* namespaces or projects as module boundaries
* public contract namespaces
* module-owned shared contract namespaces
* internal implementations
* dependency injection for composition
* architecture tests where useful

## Node / NestJS

Use:

* feature modules
* exported providers or contracts
* strict module exports
* private internal providers
* explicit public events
* module-owned DTO or contract locations

## Go

Use:

* package boundaries
* exported module APIs
* internal packages
* explicit dependency composition
* narrow capability-oriented interfaces
* module-owned boundary structs

---

# Architectural Intent

This architecture intentionally favors:

* strong feature ownership
* explicit module boundaries
* hidden implementation details
* small and understandable public surfaces
* module-owned persistence
* explicit data ownership
* DTO ownership
* controlled cross-module interaction
* acyclic dependencies
* explicit orchestration
* recoverable workflows
* feature-oriented locality
* pragmatic internal architecture
* architectural clarity over architectural purity
* scalability of understanding as the codebase grows

The architecture intentionally avoids:

* global horizontal business layers
* shared persistence models
* ownerless business DTOs
* cross-module repository access
* direct cross-module table access
* giant universal service interfaces
* interface-per-method ceremony
* hidden business orchestration in infrastructure
* global transactional assumptions
* uncontrolled event coupling
* circular module dependencies
* abstraction for abstraction's sake
* `shared` or `common` folders becoming architectural dumping grounds

---

# Core Mental Model

Think of each module as a small application inside the larger application.

Each feature module:

```text
owns its behavior
owns its domain
owns its data
owns its transactions
hides its implementation
publishes explicit capabilities
publishes explicit integration events
owns its public DTO semantics
```

Other modules may know only what the module deliberately exposes.

For workflows spanning multiple modules:

```text
Feature modules own business state.

Orchestration modules own workflow state.

Public contracts express synchronous capabilities.

Public events express completed facts.

Shared DTOs express public data contracts while retaining module ownership.

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
* data ownership remains enforceable
* DTO ownership remains visible
* failures can be recovered from deliberately
* architectural boundaries survive growth
* developers can reason about one area without loading the entire system into their heads
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
