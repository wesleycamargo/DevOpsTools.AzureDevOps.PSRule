
# Synopsis: The target should satisfy its applicable organizational policy
Rule 'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest' `
    -Ref 'ADO-YAML-001' `
    -Type 'Azure.DevOps.Pipelines.PipelineYaml' `
    -If { (Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest').Outcome -in @('Pass', 'Fail') } `
    -Tag @{ release = 'GA'; assessment = 'Policy' } `
    -Level Warning {
        $assessment = Get-AzDevOpsPolicyAssessment -TargetObject $TargetObject -RuleId 'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest' -Policy $Configuration.assessmentPolicies.'Azure.DevOps.Pipelines.PipelineYaml.AgentPoolVersionNotLatest'
        Reason $assessment.ReasonCode
        Recommend 'Apply the referenced organizational policy or collect the missing evidence.'
        $Assert.HasFieldValue($assessment, 'Outcome', 'Pass')
}

# Synopsis: All steps should have a display name
Rule 'Azure.DevOps.Pipelines.PipelineYaml.StepDisplayName' `
    -Ref 'ADO-YAML-002' `
    -Type 'Azure.DevOps.Pipelines.PipelineYaml' `
    -Tag @{ release = 'GA'} `
    -Level Warning {
        # Description 'All steps should have a display name'
        Reason 'Step is missing a display name'
        Recommend 'Add a display name to the step'
        # Links ''
        AllOf {
            If($TargetObject.stages) {
                $TargetObject.stages | ForEach-Object {
                    $Assert.HasField($_, "jobs", $true)
                    $_.jobs | ForEach-Object {
                        $Assert.HasField($_, "steps", $true)
                        $_.steps | ForEach-Object {
                            $Assert.HasField($_, "displayName", $true)
                            $Assert.HasFieldValue($_, "displayName")
                        }
                    }
                }
            }
            elseif ($TargetObject.jobs) {
                $Assert.HasField($TargetObject, "jobs", $true)
                $TargetObject.jobs | ForEach-Object {
                    $Assert.HasField($_, "steps", $true)
                    $_.steps | ForEach-Object {
                        $Assert.HasField($_, "displayName", $true)
                        $Assert.HasFieldValue($_, "displayName")
                    }
                }
            }
            else {
                $Assert.HasField($TargetObject, "steps", $true)
                $TargetObject.steps | ForEach-Object {
                    $Assert.HasField($_, "displayName", $true)
                    $Assert.HasFieldValue($_, "displayName")
                }
            }
        }
}
