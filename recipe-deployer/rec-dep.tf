terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}


variable "SPACE" {}
variable "GLOBALVARIABLES" {}
variable "CLOUDINTEGRATIONS" {}
variable "STACKS" {}
variable "DEPENDENCIES" {}



locals {
  TFGH-stacks              = [for s in var.STACKS : s if s["Type"] == "TFGH"]
  NAME_TO_PARAMETERS       = zipmap([for x in local.TFGH-stacks : x["Name"]], [for x in local.TFGH-stacks : x["Parameters"]])
  NAME_TO_CLOUDINTEGRATION = zipmap([for x in local.TFGH-stacks : x["Name"]], [for x in local.TFGH-stacks : x["CloudIntegration"]])
  TFGH-MAPPING = { for k, v in local.NAME_TO_PARAMETERS : k => { "Parameters" = local.NAME_TO_PARAMETERS[k],
    "CloudIntegration" = {
      "Name"  = local.NAME_TO_CLOUDINTEGRATION[k],
      "Id"    = var.CLOUDINTEGRATIONS[local.NAME_TO_CLOUDINTEGRATION[k]].Id,
      "read"  = var.CLOUDINTEGRATIONS[local.NAME_TO_CLOUDINTEGRATION[k]].read,
      "write" = var.CLOUDINTEGRATIONS[local.NAME_TO_CLOUDINTEGRATION[k]].write
    }
    }
  }
}



resource "spacelift_space" "recipe_space" {
  name             = join("_", [var.SPACE.Name, var.SPACE.Family, replace(var.SPACE.Version, ".", "-")])
  parent_space_id  = var.SPACE.Parent_ID
  description      = var.SPACE.Description
  inherit_entities = true
}


resource "spacelift_context" "space-context" {
  description = "Configuration details for the compute cluster"
  name        = join("_", [var.SPACE.Name, var.SPACE.Family, replace(var.SPACE.Version, ".", "-")])
  space_id    = spacelift_space.recipe_space.id
}


resource "spacelift_environment_variable" "context-variables" {
  count      = length(var.GLOBALVARIABLES)
  context_id = spacelift_context.space-context.id
  name       = join("_", ["TF_VAR", var.GLOBALVARIABLES[count.index]["name"]])
  value      = var.GLOBALVARIABLES[count.index]["value"]
  write_only = var.GLOBALVARIABLES[count.index]["secret"]
}


resource "spacelift_stack" "TFGH-stacks" {
  for_each = local.TFGH-MAPPING
  name = join("_", [var.SPACE.Family, var.SPACE.Name, replace(var.SPACE.Version, ".", "-"),
  local.TFGH-MAPPING[each.key]["Parameters"]["name"]])
  space_id          = spacelift_space.recipe_space.id
  administrative    = local.TFGH-MAPPING[each.key]["Parameters"]["administrative"]
  autodeploy        = local.TFGH-MAPPING[each.key]["Parameters"]["autodeploy"]
  branch            = local.TFGH-MAPPING[each.key]["Parameters"]["branch"]
  description       = local.TFGH-MAPPING[each.key]["Parameters"]["description"]
  project_root      = local.TFGH-MAPPING[each.key]["Parameters"]["project_root"]
  repository        = local.TFGH-MAPPING[each.key]["Parameters"]["repository"]
  terraform_version = local.TFGH-MAPPING[each.key]["Parameters"]["terraform_version"]
}


resource "spacelift_context_attachment" "attach-to-TFGH" {
  for_each   = local.TFGH-MAPPING
  context_id = spacelift_context.space-context.id
  stack_id   = spacelift_stack.TFGH-stacks[each.key].id
  priority   = 0
}


resource "spacelift_aws_integration_attachment" "AWS-integration-to-TFGH" {
  for_each       = local.TFGH-MAPPING
  integration_id = local.TFGH-MAPPING[each.key]["CloudIntegration"].Id
  stack_id       = spacelift_stack.TFGH-stacks[each.key].id
  read           = local.TFGH-MAPPING[each.key]["CloudIntegration"].read
  write          = local.TFGH-MAPPING[each.key]["CloudIntegration"].write
}



output "TFGH-MAPPING" {
  value = local.TFGH-MAPPING
}


output "CREATED-TFGH-STACKS" {
  value     = spacelift_stack.TFGH-stacks
  sensitive = true
}