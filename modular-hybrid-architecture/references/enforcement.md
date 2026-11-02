# Architecture Enforcement

> Part of the Modular Hybrid Architecture skill. Read this when turning module boundaries into automated checks, or when reviewing a codebase for semantic boundary violations.

## Architecture Enforcement

Structural architecture rules should be automated where useful.

Semantic architectural judgment should remain a code-review responsibility.

The architecture should not become difficult to work with merely because every possible rule has been automated.

Enforce boundaries that protect meaningful ownership.

Avoid enforcement for enforcement's sake.

---

## Hard Structural Rules

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

## Java: ArchUnit Template

Add ArchUnit as a test dependency (use the current `archunit-junit5` version):

```kotlin
testImplementation("com.tngtech.archunit:archunit-junit5:<current-version>")
```

Replace `com.example.app` with your base package. The test below is a starting point — adapt package names, then duplicate the per-module rules for each business module.

```java
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

@AnalyzeClasses(
    packages = "com.example.app",
    importOptions = ImportOption.DoNotIncludeTests.class
)
class ModuleBoundaryTest {

    // 1. Module dependency graph must be acyclic.
    @ArchTest
    static final ArchRule modules_are_free_of_cycles =
        slices()
            .matching("com.example.app.(*)..")
            .should()
            .beFreeOfCycles();

    // 2. Another module may only use this module's public root types.
    @ArchTest
    static final ArchRule orders_internals_are_private =
        noClasses()
            .that().resideOutsideOfPackage("com.example.app.orders..")
            .should().accessClassesThat()
            .resideInAnyPackage(
                "com.example.app.orders.services..",
                "com.example.app.orders.endpoint..",
                "com.example.app.orders.models.."
            )
            .because("Orders internals are private; use orders.* public contracts");

    // 3. Persistence entities must not cross module boundaries.
    @ArchTest
    static final ArchRule orders_entities_are_private =
        noClasses()
            .that().resideOutsideOfPackage("com.example.app.orders..")
            .should().accessClassesThat()
            .resideInAPackage("com.example.app.orders.services.persistence.entities..")
            .because("persistence entities are private to their owning module");

    // 4. Domain logic must not depend on framework, persistence, or runtime.
    @ArchTest
    static final ArchRule orders_domain_is_independent =
        noClasses()
            .that().resideInAPackage("com.example.app.orders.services.domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage(
                "com.example.app.orders.endpoint..",
                "com.example.app.orders.services.persistence..",
                "com.example.app.orders.services.messaging..",
                "com.example.app.orders.services.integrations..",
                "com.example.app.orders.runtime.."
            );

    // 5. Modules must not depend on root runtime.
    @ArchTest
    static final ArchRule modules_do_not_depend_on_root_runtime =
        noClasses()
            .that().resideInAnyPackage(
                "com.example.app.orders..",
                "com.example.app.customers..",
                "com.example.app.payments.."
            )
            .should().dependOnClassesThat()
            .resideInAPackage("com.example.app.runtime..");

    // 6. Shared boundary DTOs must not reach back into the owning module.
    @ArchTest
    static final ArchRule shared_orders_is_standalone =
        noClasses()
            .that().resideInAPackage("com.example.app.shared.orders..")
            .should().dependOnClassesThat()
            .resideInAPackage("com.example.app.orders..")
            .because("shared DTOs are standalone boundary types");
}
```

Marker annotation used by rule 3:

If internal types are scattered across packages rather than living in predictable
`services/`, `persistence/`, and `models/` packages, introduce a `@ModuleInternal`
annotation and add a per-module rule that outside classes may not depend on
annotated types in that module's package.

### Rolling out on a legacy codebase

Do not attempt a big-bang cleanup. Encode the target rules, then freeze existing violations so new violations fail the build:

```java
import com.tngtech.archunit.library.freeze.FreezingArchRule;

@ArchTest
static final ArchRule modules_are_free_of_cycles =
    FreezingArchRule.freeze(
        slices()
            .matching("com.example.app.(*)..")
            .should()
            .beFreeOfCycles());
```

Remove frozen violations as the refactor progresses. Delete the freeze once the stored baseline is empty.

---

## Other Stacks

The same rules map to other ecosystems:

| Stack | Tool |
|---|---|
| Java / Kotlin | ArchUnit, jMolecules |
| .NET / C# | NetArchTest.Rules, ArchUnitNET |
| Node / TypeScript | dependency-cruiser, eslint-plugin-boundaries, `madge --circular` |
| Go | go-arch-lint, `go list -deps`, or a package-graph test |
| PHP | deptrac |
| Python | import-linter contracts |
| Rust | `cargo modules` dependency graph + a CI check |

Pick the tool that expresses *ownership*, not merely package layering. A tool that only enforces layers inside a module does not prove that module boundaries are respected.

---

## Semantic Review Rules

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

Use `references/review-checklist.md` to make a semantic review repeatable.
