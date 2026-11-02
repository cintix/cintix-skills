# Module Boundaries

> Part of the Modular Hybrid Architecture skill. Read this when deciding module ownership, public contracts, DTO placement, or internal module structure.

## Modules

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

## Module Layout

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

## Module Public API

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

## Public Contract Rules

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

## Shared DTO Ownership

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

## Shared DTO Rules

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

## Avoid Unowned Shared Types

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

## Local Models

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

## Internal Module Architecture

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

## Internal Dependency Rules

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
