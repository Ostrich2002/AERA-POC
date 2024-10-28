# locals {

#   sub_folders1_var = compact(flatten([for k, i in var.folder_map : length(i) == 0 ? [] : [for ip1, op1 in i : join("=1>", [k, ip1])]]))

#   sub_folders2_var = compact(flatten([for k, i in var.folder_map : length(i) == 0 ? [] : [for ip1, op1 in i : length(op1) == 0 ? [] : [for ip2, op2 in op1 : join("=2>", [join("=1>", [k, ip1]), ip2])]]]))

# }

# module "folders" {
#   source  = "terraform-google-modules/folders/google"
#   version = "~> 4.0"

#   for_each = var.folder_map
#   parent   = "organizations/${var.org_id}"
#   names    = each.key[*]
# }

# module "sub_folders1" {
#   source  = "terraform-google-modules/folders/google"
#   version = "~> 4.0"

#   for_each = toset(local.sub_folders1_var)
#   parent   = module.folders[element(split("=1>", each.value), 0)].id
#   names    = [element(split("=1>", each.value), 1)]
# }

# module "sub_folders2" {
#   source  = "terraform-google-modules/folders/google"
#   version = "~> 4.0"

#   for_each = toset(local.sub_folders2_var)
#   parent   = module.sub_folders1[element(split("=2>", each.value), 0)].id
#   names    = [element(split("=2>", each.value), 1)]
# }


# #new addition for projects
# # Create projects in the sub-folders (US: management, build, networking)
# module "projects" {
#   source  = "terraform-google-modules/project-factory/google"
#   version = "~> 16.0"

#   for_each = toset([for k, v in var.folder_map["aera-build-infra-services"]["US"] : k])

#   name       = "${each.key}-project"
#   org_id     = var.org_id
#   folder_id  = module.sub_folders1["aera-build-infra-services=1>US"].id
#   billing_account = var.billing_account_id

#   labels = {
#     folder = each.key
#   }

# }

# # IAM Binding for projects
# # resource "google_project_iam_member" "project_iam" {
# #   for_each = { for k in keys(var.folder_map["aera-build-infra-services"]["US"]) : k => k }

# #   project = module.projects[each.key].project_id
# #   role    = "roles/editor"
# #   member  = "user:${var.project_owner_email}"
# # }
# resource "google_project_iam_member" "project_iam" {
#   for_each = { for k in keys(var.folder_map["aera-build-infra-services"]["US"]) : k => k }
#   project  = module.projects[each.key].project_id
#   role     = "roles/editor"
#   member   = "serviceAccount:${var.project_owner_email}"  
# }

# # Optional: IAM Binding for folders
# resource "google_folder_iam_member" "folder_iam" {
#   for_each = toset(local.sub_folders1_var)

#   folder = module.sub_folders1[each.value].id
#   role   = "roles/resourcemanager.folderAdmin"
#   member = "serviceAccount:${var.project_owner_email}"  
# }

# # Billing Account IAM
# resource "google_billing_account_iam_member" "billing_account" {
#   billing_account_id = var.billing_account_id
#   role               = "roles/billing.user"  # or "roles/billing.admin" if more access is needed
#   member             = "user:${var.billing_account_user_email}"
# }





#---------------------------------------NEW APPROACH------------------------
provider "google" {
  alias                      = "impersonated"
  project                    = var.admin_project_id
  scopes                     = ["https://www.googleapis.com/auth/cloud-platform","https://www.googleapis.com/auth/cloud-billing"]
  impersonate_service_account = "anshu.priya@cloudsufi.com"  # User account to impersonate
}

# Local variables for nested folders to target for project creation
locals {
  sub_folders1_var = compact(flatten([
    for k, i in var.folder_map :
    length(i) == 0 ? [] : [for ip1, op1 in i : join("=1>", [k, ip1])]
  ]))

  sub_folders2_var = compact(flatten([
    for k, i in var.folder_map :
    length(i) == 0 ? [] : [for ip1, op1 in i :
    length(op1) == 0 ? [] : [for ip2, op2 in op1 : join("=2>", [join("=1>", [k, ip1]), ip2])]]
  ]))

  target_folders = compact(flatten([
    for k, i in var.folder_map :
    length(i) == 0 ? [] : [for ip1, op1 in i :
    length(op1) == 0 ? [] : [for ip2, op2 in op1 : join("=2>", [join("=1>", [k, ip1]), ip2])]]
  ]))
}

module "folders" {
  source  = "terraform-google-modules/folders/google"
  version = "~> 4.0"

  for_each = var.folder_map
  parent   = "organizations/${var.org_id}"
  names    = each.key[*]
}

module "sub_folders1" {
  source  = "terraform-google-modules/folders/google"
  version = "~> 4.0"

  for_each = toset(local.sub_folders1_var)
  parent   = module.folders[element(split("=1>", each.value), 0)].id
  names    = [element(split("=1>", each.value), 1)]
}

module "sub_folders2" {
  source  = "terraform-google-modules/folders/google"
  version = "~> 4.0"

  for_each = toset(local.sub_folders2_var)
  parent   = module.sub_folders1[element(split("=2>", each.value), 0)].id
  names    = [element(split("=2>", each.value), 1)]
}

resource "random_id" "project_suffix" {
  byte_length = 2
}

# Loop over the target folders and create projects
# Example of specifying the aliased provider in the project creation module
module "projects" {
  source    = "terraform-google-modules/project-factory/google"
  version   = "~> 12.0"
  
  providers = {
    google = google.impersonated
  }

  for_each        = toset(local.target_folders)
  name            = "project-${element(split("=2>", each.value), 1)}"
  project_id      = "project-${element(split("=2>", each.value), 1)}-${random_id.project_suffix.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account
  folder_id       = module.sub_folders2[each.value].id
}


# IAM bindings for each created project
resource "google_project_iam_member" "project_permissions" {
  for_each = { for k, v in module.projects : k => v }

  project = each.value.project_id
  role    = element(var.project_permissions, 0)  # Adjust this if you want to assign multiple roles
  member  = "user:${element(var.project_owners, 0)}"  # Replace with actual members
}

resource "google_project_iam_member" "project_editor" {
  for_each = { for k, v in module.projects : k => v }

  project = each.value.project_id
  role    = element(var.project_permissions, 1)  # Adjust this if you want to assign multiple roles
  member  = "user:${element(var.project_owners, 0)}"  # Replace with actual members
}