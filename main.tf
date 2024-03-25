module "RECIPE-DEPLOYER" {
  source            = "./recipe-deployer"
  SPACE             = local.SPACE
  GLOBALVARIABLES   = local.GLOBALVARIABLES
  CLOUDINTEGRATIONS = local.CLOUDINTEGRATIONS
  STACKS            = local.STACKS
  DEPENDENCIES      = local.DEPENDENCIES
}



module "DEP-BUILDER" {
  source     = "./dependency-builder"
  depends_on = [module.RECIPE-DEPLOYER]
  count      = length(local.DEPENDENCIES)
  SRC_STACK  = module.RECIPE-DEPLOYER.CREATED-TFGH-STACKS[local.DEPENDENCIES[count.index]["Src"]["StackName"]].id
  DST_STACK  = module.RECIPE-DEPLOYER.CREATED-TFGH-STACKS[local.DEPENDENCIES[count.index]["Dst"]["StackName"]].id
  SRC_PARAM  = local.DEPENDENCIES[count.index]["Src"]["ParamName"]
  DST_PARAM  = local.DEPENDENCIES[count.index]["Dst"]["ParamName"]
}



