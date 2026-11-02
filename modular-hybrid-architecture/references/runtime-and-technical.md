# Runtime and Technical Capabilities

> Part of the Modular Hybrid Architecture skill. Read this when deciding where runtime, composition roots, or reusable technical capabilities belong.

## Technical Capabilities

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

## Reusable Technical Modules

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

## Technical Module Rules

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

## Runtime Ownership

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

## Shared Runtime

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

## Runtime Promotion

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

## Runtime Rules

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

## Composition Root

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
