# ADR-001: Separate collection from evaluation

## Status

Recorded from implementation on 10 October 2026. Historical approval is unknown.

## Context

Azure DevOps access depends on credentials, API availability, and permission profiles.
Rule evaluation needs stable target metadata and repeatable input.

## Decision

Collectors export JSON before PSRule evaluates the data.
Exported objects carry `ObjectType` and `ObjectName`. Module bindings map these properties to rule targets.
Project exports and organization exports share this contract.

## Alternatives considered

Live API calls inside rules would couple evaluation to network access and credential handling.
A database between collection and evaluation would add infrastructure to basic module usage.
These are analytical alternatives. The repository does not record a historical selection process.

## Consequences

Operators can reevaluate an export without recollecting data.
Rules and collectors can evolve separately while they preserve the binding contract.
Exports become stale after collection. Exported files also require access and retention controls.
Changes to target metadata can affect rules, tests, and downstream reports.

## References

- [Module loader and aggregate exporters](../../src/DevOpsTools.AzureDevOps.PSRule/DevOpsTools.AzureDevOps.PSRule.psm1).
- [PSRule bindings](../../src/DevOpsTools.AzureDevOps.PSRule/rules/Config.Rule.yaml).
