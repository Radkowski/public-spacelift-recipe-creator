terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}


variable "SRC_STACK" {}
variable "DST_STACK" {}
variable "SRC_PARAM" {}
variable "DST_PARAM" {}



resource "spacelift_stack_dependency" "stack-dep" {
  stack_id            = var.DST_STACK
  depends_on_stack_id = var.SRC_STACK
}


resource "spacelift_stack_dependency_reference" "stack-dep-ref" {
  stack_dependency_id = spacelift_stack_dependency.stack-dep.id
  output_name          = var.SRC_PARAM
  input_name         = join("_", ["TF_VAR", var.DST_PARAM])
}


