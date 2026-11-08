---
category: Microsoft Azure DevOps Repos
severity: Severe
online version: https://github.com/wesleycamargo/DevOpsTools.AzureDevOps.PSRule/blob/main/src/DevOpsTools.AzureDevOps.PSRule/nl/Azure.DevOps.Repos.BranchPolicyRequireBuild.md
---

# Azure.DevOps.Repos.BranchPolicyRequireBuild

## SYNOPSIS

Een build of CI-pijplijn moet worden geconfigureerd om te worden uitgevoerd voordat
wijzigingen kunnen worden samengevoegd in de standaardbranch.

## DESCRIPTION

De branch policy moet worden geconfigureerd om een build of CI-pijplijn te vereisen
om te worden uitgevoerd voordat wijzigingen kunnen worden samengevoegd in de
standaardbranch. Dit zorgt ervoor dat wijzigingen worden gevalideerd voordat ze
worden samengevoegd in de standaardbranch. Deze regel valideert niet dat de build
of CI-pijplijn correct is geconfigureerd.
De regel valideert dat een toepasselijke build policy is ingeschakeld en
blokkerend is en dat de vereiste buildinstellingen aanwezig zijn; de regel
bewijst niet dat een build succesvol is uitgevoerd.

Mininum TokenType: `ReadOnly`

## RECOMMENDATION

Overweeg om de branch policy in te schakelen om een build of CI-pijplijn te vereisen.

## LINKS

- [Create a branch policy](https://docs.microsoft.com/nl-nl/azure/devops/repos/git/branch-policies?view=azure-devops)
- [Branch policies](https://docs.microsoft.com/nl-nl/azure/devops/repos/git/branch-policies-overview?view=azure-devops)
- [Azure DevOps Security best practices](https://docs.microsoft.com/nl-nl/azure/devops/user-guide/security-best-practices?view=azure-devops#policies)

## BEWIJS

Een toepasselijke branch policy moet zowel ingeschakeld (`isEnabled = true`)
als blokkerend (`isBlocking = true`) zijn. Het policytype en de relevante
instellingen moeten ook aan deze regel voldoen. Alleen de aanwezigheid van
beleid is niet voldoende: uitgeschakeld of uitsluitend adviserend beleid
biedt geen afdwingbare branchbescherming. Een adviserende policy telt daarom
niet als verplichte bescherming.
