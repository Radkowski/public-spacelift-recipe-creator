locals {
  user_data         = fileexists("./config.yaml") ? yamldecode(file("./config.yaml")) : jsondecode(file("./config.json"))
  SPACE             = local.user_data.Recipe.Space
  GLOBALVARIABLES   = local.user_data.Recipe.GlobalVariables
  CLOUDINTEGRATIONS = local.user_data.Recipe.CloudIntegrations
  STACKS            = local.user_data.Recipe.Stacks
  DEPENDENCIES      = local.user_data.Recipe.Dependencies
}


