# Intent: Trustworthy Azure DevOps assessments

## Problem
Two reviews identified false policy outcomes, incomplete discovery, misclassified collection failures, authentication defects, and validation/release gaps across the rules and dashboard repositories.

## Desired Outcome
Assessment findings reflect enforced controls and complete evidence. Incomplete collection prevents evaluation and publication. Security violations remain advisory.

## Scope
Address both reviews: policy enforcement and scope matching; pagination; file error classification; organization collection independent of projects; token refresh and UTC expiry; production applicability; secret detection precision; strict dashboard collection; CI triggers, dependency versions, failure propagation and artifacts; explicit manual publishing inputs. Retain live integration coverage and add focused offline regressions. Validate Azure DevOps pipelines using candidate sources where access permits.

## Constraints
User authorized implementation, branches, PRs, pipeline updates and live validation on 2026-10-20. Merging to main requires user approval. Preserve existing local changes and intentionally insecure test fixtures. Do not broaden credentials or change production security settings to make tests pass.

## Success Criteria
Boundary regressions pass, existing offline suites pass, incomplete exports cannot publish findings, and reviewable branches and operational validation evidence are available. Any access-dependent gap is explicit.
