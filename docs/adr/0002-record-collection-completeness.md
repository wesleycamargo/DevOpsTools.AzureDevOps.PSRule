# ADR-002: Record collection completeness separately

## Status

Recorded from implementation on 10 October 2026. Adoption differs across pipelines.

## Context

A collector can fail or lack permissions while other collectors succeed.
A rule result alone cannot establish whether all required input reached evaluation.

## Decision

Aggregate export records collection status separately from rule results.
Collectors continue after individual failures. Strict export rejects incomplete required coverage after the collection attempt.
The completeness report remains outside the PSRule input directory.
The weekly assessment enables this contract. The manual workbook assessment currently does not.

## Alternatives considered

Stopping at the first collector failure would discard remaining collection evidence.
Using only SARIF would mix rule outcomes with evidence about missing input.
These are analytical alternatives. The repository does not record a historical selection process.

## Consequences

Operators can distinguish policy failures from collection gaps.
Strict assessment avoids evaluating incomplete required coverage.
Consumers must explicitly enable strict export and retain the status report.
Legacy consumers can still evaluate incomplete inputs.

## References

- [Completeness contract](../assessment-completeness.md).
- [Completeness implementation](../../src/DevOpsTools.AzureDevOps.PSRule/Functions/AssessmentCompleteness.ps1).
- [Weekly assessment](../../pipelines/psrule-assessment.yml).
