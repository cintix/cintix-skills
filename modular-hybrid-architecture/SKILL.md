# Modular Hybrid Architecture Skill — v1.3

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

This applies to:

```text
models
DTOs
services
persistence
runtime
configuration
messaging
integrations
workers
technical helpers
framework adapters
```

Example:

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

Examples of module bleeding include:

```text
shared/customers/CustomerDto
```

when only Customers uses the DTO.

```text
runtime/customer-worker
```

when the worker belongs only to Customers.

```text
modules/database
```

when only one module uses the database capability.

```text
common/CustomerMapper
```

when the mapper exists only for Customers.

Module bleeding weakens locality and makes ownership harder to understand.

It often happens because code is moved outward:

* in anticipation of future reuse
* because it looks more architecturally organized
* because something uses a technical framework
* because two implementations look similar
* because a reference architecture contains a corresponding folder

Avoid this.

Core rule:

> Do not move code outward merely because it could theoretically be reused.

---

# Architectural Promotion

Responsibilities may move outward when their ownership genuinely expands.

Conceptually:

```text
local module responsibility
        ↓
real cross-module need appears
        ↓
promote outward
```

Promotion should follow actual system needs.

For example:

```text
customers/
  models/
    CustomerDto.java
```

may later become:

```text
shared/
  customers/
    CustomerDto.java
```

when other modules legitimately consume the DTO.

Likewise:

```text
orders/
  runtime/
    worker/
```

remains inside Orders while the worker belongs only to Orders.

A root-level runtime becomes appropriate only when the runtime itself spans multiple modules.

Promotion is intentional architectural evolution.

It should not be speculative.

---

# Project Structure Is Progressive

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

This may already satisfy the architecture completely.

As the application grows:

```text
customers/
orders/
payments/
```

may become:

```text
modules/
  customers/
  orders/
  payments/
```

when grouping the modules improves navigation.

If modules begin sharing boundary DTOs:

```text
shared/
  customers/
  orders/
```

may become useful.

If one runtime begins composing several modules:

```text
runtime/
  api/
```

may become useful.

The root structure should emerge from actual responsibilities.

Core rule:

> Folders are created because boundaries exist.

> Boundaries are not invented because folders exist in the reference architecture.

---

# Structural Readability

Architecture exists for developers as well as compilers.

The filesystem should make ownership and intent visible.

A developer should be able to inspect the project structure and quickly answer questions such as:

```text
Where does this capability belong?

Who owns this model?

Is this type shared?

Does this runtime belong to one module or several?

What may another module consume?

Where is the implementation hidden?
```

The theoretically pure location is not always the most useful location for humans.

Consistency, discoverability, and readability are legitimate architectural concerns.

Core rule:

> A good architecture should make the right place for new code feel obvious.

The filesystem is therefore part of the architecture contract.

---

# Modules

A module represents a cohesive capability with clear ownership.

Most modules represent business or domain capabilities.

Examples:

```text
customers
orders
payments
inventory
subscriptions
checkout
fulfillment
```

A module should behave conceptually like a small application inside the larger system.

It may own:

```text
public contracts
domain models
services
persistence
runtime
integrations
configuration
events
transactions
local technical behavior
```

Not every module needs all of these.

A module should contain only the structure its complexity requires.

---

# Module Layout

A larger module may look like:

```text
orders/

  Orders.java
  OrderQueries.java
  OrderAdministration.java
  OrderEvents.java

  endpoint/

  models/

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

    messaging/

    integrations/

  runtime/
```

A smaller module may look like:

```text
pricing/
  Pricing.java
  PricingService.java
```

or:

```text
customers/
  Customers.java
  Customer.java
  CustomerRepository.java
  Main.java
```

Both are valid.

Do not create empty directories or abstraction layers simply to match the reference structure.

---

# Module Public API

The public API of a module consists of the capabilities and public boundary contracts it intentionally exposes.

Public behavior contracts and public integration events should normally remain clearly visible near the module root.

Example:

```text
orders/
  Orders.java
  OrderQueries.java
  OrderAdministration.java
  OrderEvents.java

  services/
    ...
```

Other modules may import:

```java
import orders.Orders;
import orders.OrderQueries;
```

They may not import implementation details such as:

```java
import orders.services.OrdersService;
import orders.services.persistence.OrderRepository;
import orders.services.domain.Order;
```

Shared DTOs owned by the module may live under:

```text
shared/orders/
```

when genuine cross-module consumption makes that location useful.

The externally visible API of a module therefore consists of:

```text
module public contracts
+
module public events
+
module-owned shared boundary DTOs
```

---

# Public Contract Rules

1. Public module contracts are the only synchronous cross-module entry points.
2. Public contracts should represent cohesive business capabilities.
3. Split contracts when they become conceptually broad.
4. Do not create one interface per individual method or use case.
5. Do not expose repositories, mappers, factories, validators, internal managers, persistence entities, or implementation abstractions as public module contracts.
6. Public contracts should expose behavior rather than implementation details.
7. Public contracts must never expose persistence entities or internal domain models.
8. Public contract implementations remain inside the owning module.
9. Public contracts should remain focused and understandable.
10. A large public API surface is an architectural review signal even if all structural rules are technically followed.

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

unless those concepts genuinely represent stable capabilities.

Avoid both:

```text
one 150-method interface
```

and:

```text
150 one-method interfaces
```

Split by stable capability, not arbitrary operation count.

---

# Shared DTO Ownership

`shared` exists for publicly consumable boundary data that genuinely crosses module boundaries.

It is not a required project folder.

If no data is shared between modules, there is no reason to create it.

When required:

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

Every business DTO has exactly one owning module.

For example:

```text
shared/customers/CustomerDto.java
```

means:

> CustomerDto is publicly consumable, but Customers owns its meaning and evolution.

Other modules may consume it.

They do not gain ownership of it.

---

# Shared DTO Rules

1. Use `shared` only when a boundary type is genuinely consumed outside its owning module.
2. Every shared business DTO must belong to exactly one owning module.
3. Shared module-owned DTOs should be placed under:

```text
shared/<module>/
```

4. The owning module defines the DTO's meaning, structure, and evolution.
5. Other modules may consume the DTO but must not redefine its semantics.
6. Shared DTOs are boundary and transport types only.
7. Shared DTOs must not become the application's shared domain model.
8. Shared DTOs must not contain module-specific business behavior.
9. Persistence entities must never be placed in `shared`.
10. Internal domain models must never be placed in `shared`.
11. A shared DTO does not imply shared ownership of the underlying business state.
12. Consumers should map shared DTOs into their own representation when local business behavior or invariants require it.
13. A DTO being used by many modules does not make it ownerless.
14. DTO ownership should remain visible directly in the folder or package structure.
15. Do not promote a local DTO into `shared` merely because it might be useful later.

Conceptually:

```text
customers/
  internal Customer model
        ↓
shared/customers/
  CustomerDto
        ↓
orders/
  consumer representation
```

Ownership remains with Customers.

---

# Avoid Unowned Shared Types

Avoid:

```text
shared/
  dto/
    CustomerDto.java
    OrderDto.java
    PaymentDto.java
```

because ownership becomes unclear.

Also avoid turning:

```text
shared/common/
```

into a general dumping ground.

A small common area may exist for genuinely ownerless boundary concepts such as:

```text
shared/
  common/
    PageDto.java
    ErrorDto.java
```

but it should remain intentionally small.

Core rule:

> `shared` means intentionally shared boundary data.

It does not mean:

> data that belongs to everybody.

---

# Local Models

Types used only by one module remain inside that module.

Example:

```text
customers/
  models/
    CustomerDto.java
    CustomerSummary.java
```

There is no architectural advantage in placing these under root `shared` when no external consumer exists.

If another module later requires one of these types, the type may be promoted into:

```text
shared/customers/
```

if that is the appropriate public boundary representation.

Local first always wins until actual sharing exists.

---

# Internal Module Architecture

Each module may internally use Clean Architecture principles where they provide value.

Clean Architecture is an internal implementation technique.

It is not the global project structure.

Inside a module:

* domain logic should remain independent from framework and persistence concerns where that independence matters
* persistence adapts storage to the module's needs
* services coordinate internal behavior
* endpoints adapt external requests into module operations
* integrations adapt external systems to module needs
* internal abstractions should exist only when they provide meaningful value

Avoid:

* unnecessary abstraction layers
* command-handler explosion
* repository interfaces with no meaningful boundary value
* one-class-per-operation ceremony
* abstractions introduced only to satisfy a pattern
* framework-shaped domain models where unnecessary
* domain rules scattered across unrelated areas
* moving technical code out of the module merely because it uses infrastructure technology

Core rule:

> The module boundary matters more than internal architectural purity.

---

# Internal Dependency Rules

1. Endpoints may call internal services or public-contract implementations.
2. Internal services may depend on domain logic and module-private abstractions.
3. Domain logic should not depend on endpoint, persistence, framework, runtime, or another module's internals.
4. Persistence may depend on internal domain representations where mapping is required.
5. Persistence entities remain private to the owning module.
6. Cross-module calls may target only public contracts.
7. Public contract implementations may coordinate internal services and domain behavior.
8. Domain logic should not know how it is persisted.
9. Module internals may evolve freely as long as public contracts remain compatible.
10. Module-specific persistence, messaging, runtime, configuration, and integration logic stays inside the module unless a real shared responsibility emerges.

---

# Technical Capabilities

Technical behavior is local by default.

Using a database, queue, cache, HTTP client, logger, serializer, or external framework does not automatically justify a global technical module.

Example:

```text
orders/
  persistence/
  messaging/
```

is correct if those concerns belong only to Orders.

If multiple modules eventually require the same cohesive technical capability, it may be promoted into a reusable module.

For example:

```text
modules/
  messaging/
```

may become appropriate when several modules genuinely share the same transport capability.

But reuse should be demonstrated, not predicted.

Core rule:

> Technology does not determine ownership.

> Responsibility determines ownership.

---

# Reusable Technical Modules

A reusable technical capability may become a module when actual cross-module use justifies it.

Examples may include:

```text
database
messaging
logging
serialization
cache
files
clock
http
```

Such modules follow the same encapsulation principles as business modules.

Example:

```text
modules/
  messaging/
    Messaging.java

    services/
      KafkaMessaging.java
      serialization/
      transport/
```

A technical module may understand:

```text
message transport
delivery mechanics
broker connectivity
serialization mechanics
```

It must not understand:

```text
Order
Customer
Payment
Subscription
```

A generic messaging module may transport `OrderPlaced`.

Orders still owns:

```text
what OrderPlaced means
when OrderPlaced occurs
what data it contains
```

---

# Technical Module Rules

1. Technical capability modules are optional.
2. Do not create them before actual shared use exists.
3. They must represent a cohesive reusable capability.
4. They must expose intentional public contracts.
5. Their internal implementation remains hidden.
6. They must not own feature-specific business semantics.
7. They must not own feature persistence entities.
8. They must not become generic utility dumping grounds.
9. Shared implementation similarity alone does not justify extracting a technical module.
10. Technical modules participate in the same acyclic module dependency graph as business modules.

Avoid modules such as:

```text
utils
helpers
misc
common-services
```

unless they genuinely represent a meaningful capability.

---

# Runtime Ownership

Runtime follows ownership.

Runtime may include:

```text
process startup
dependency injection bootstrap
framework startup
hosting
worker lifecycle
schedulers
command-line entry points
runtime configuration
health checks
shutdown handling
```

If a runtime belongs to only one module, it remains inside that module.

Example:

```text
orders/
  runtime/
    api/
    worker/
```

Even if the worker is independently executable, it remains local because Orders owns it.

Core rule:

> Standalone does not mean global.

---

# Shared Runtime

A root-level `runtime` becomes appropriate only when runtime responsibility spans multiple modules.

Example:

```text
modules/
  customers/
  orders/
  payments/

runtime/
  api/
```

where the API runtime composes:

```text
Customers
Orders
Payments
```

Another example:

```text
runtime/
  worker/
```

may be appropriate if one worker runtime hosts capabilities from multiple modules.

Root-level runtime is therefore not:

> the place where all executable code lives.

It is:

> the place where shared execution responsibility lives.

---

# Runtime Promotion

A runtime begins locally.

Example:

```text
orders/
  runtime/
    worker/
```

If its responsibility later expands to coordinate or host multiple modules, it may be promoted outward:

```text
runtime/
  worker/
```

This follows the same Local First principle as DTOs and technical capabilities.

Core rule:

> Runtime stays inside its owning module unless the runtime itself becomes shared across module boundaries.

---

# Runtime Rules

1. Runtime remains inside its owning module by default.
2. Root-level runtime exists only for genuinely shared or cross-module execution contexts.
3. A standalone executable does not automatically belong in root runtime.
4. Runtime may perform startup, hosting, configuration, and dependency composition.
5. Runtime must not own feature business logic.
6. Runtime must not directly access another module's persistence.
7. Runtime must not bypass public module contracts.
8. Shared runtime must not become a hidden business orchestration layer.
9. Modules must not depend on root-level runtime.
10. Runtime-specific behavior that belongs to one module should remain inside that module.
11. Reusable capability logic discovered inside runtime should normally move into an appropriate module.
12. Runtime may know public contracts for composition and hosting, but must not use them as a substitute for business orchestration.

---

# Composition Root

Composition belongs to the runtime that owns the execution context.

For a local module runtime:

```text
orders/
  runtime/
    Main.java
    ModuleRegistry.java
```

For shared runtime:

```text
runtime/
  api/
    Main.java
    ModuleRegistry.java
```

The composition root may:

* instantiate module implementations
* connect public module contracts
* configure technical dependencies
* register adapters
* configure framework runtime behavior
* select implementations

It must not contain:

* business rules
* workflow decisions
* domain logic
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

as part of composition logic.

Core rule:

> Composition connects capabilities.

> It does not run the business workflow.

Framework dependency injection may perform physical wiring.

The architectural requirement is ownership and dependency direction, not manual construction of every object.

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

# Orchestration Rules

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

# Public and Internal Events

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

# Event Rules

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

# Data Ownership

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

# Data Ownership Rules

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

# Transactions

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

# Transaction Rules

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

# Workflow State

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

# Workflow Persistence Rules

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

# Module Dependency Graph

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

# Cycle Rules

1. Cyclic module dependencies are forbidden.
2. If modules require mutual coordination, determine who owns the resulting business outcome.
3. Move coordination into the appropriate owning feature or workflow module.
4. Public events may support legitimate reactions but must not merely disguise a dependency cycle.
5. Repeated cycles are evidence that module ownership or boundaries may need reconsideration.
6. The module dependency graph should be understandable without inspecting implementation details.
7. Root runtime must not be used as an intermediary to hide cycles.

---

# Architecture Enforcement

Structural architecture rules should be automated where useful.

Semantic architectural judgment should remain a code-review responsibility.

The architecture should not become difficult to work with merely because every possible rule has been automated.

Enforce boundaries that protect meaningful ownership.

Avoid enforcement for enforcement's sake.

---

# Hard Structural Rules

Candidates for automated enforcement include:

1. Cross-module imports may target only intentionally public module contracts, public events, and shared boundary types.
2. Imports of another module's internal services are forbidden.
3. Imports of another module's domain internals are forbidden.
4. Imports of another module's persistence internals are forbidden.
5. Persistence entities must not cross module boundaries.
6. Internal domain events must remain module-private.
7. Cyclic module dependencies are forbidden.
8. Shared business DTO ownership should remain visible under `shared/<module>/`.
9. Cross-module persistence access should be rejected where detectable.
10. Module code must not depend on shared root runtime.
11. Shared runtime must not bypass module boundaries.

For Java, tools such as ArchUnit may be suitable.

---

# Semantic Review Rules

The following normally remain review concerns:

* whether a module owns the correct capability
* whether something has been promoted outward too early
* whether module bleeding has occurred
* whether a public contract is too broad
* whether contracts have been split too aggressively
* whether a DTO genuinely needs to be shared
* whether a shared DTO has become a shared domain model
* whether DTO ownership is correct
* whether runtime is local or genuinely shared
* whether a technical capability truly deserves extraction
* whether an event represents a fact or a hidden command
* whether one module has excessive dependency fan-out
* whether workflow state is duplicating domain ownership
* whether abstractions provide real architectural value
* whether internal structure has become too ceremonial
* whether the filesystem still makes ownership easy to understand

These decisions require context.

They should not be blindly reduced to mechanical rules.

---

# Refactor Workflow

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

---

# Decision Heuristics

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

---

# Language Mapping

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

---

# Architectural Intent

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
