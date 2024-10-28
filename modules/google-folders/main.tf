# Folder creation and projects within them, linked to billing account
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

# Loop over target folders and create projects without linking to a billing account
resource "google_project" "projects" {
  for_each   = toset(local.target_folders)
  name       = "project-${element(split("=2>", each.value), 1)}"
  project_id = "project-${element(split("=2>", each.value), 1)}-${random_id.project_suffix.hex}"
  folder_id  = module.sub_folders2[each.value].id

  # Link to a billing account
  billing_account = var.billing_account
}

# Optional: IAM bindings for each created project
resource "google_project_iam_member" "project_permissions" {
  for_each = { for k, v in google_project.projects : k => v }

  project = each.value.project_id
  role    = element(var.project_permissions, 0)  # Modify roles as needed
  member  = "serviceAccount:${element(var.project_owners, 0)}"
}

resource "google_project_iam_member" "project_editor" {
  for_each = { for k, v in google_project.projects : k => v }

  project = each.value.project_id
  role    = element(var.project_permissions, 1)  # Modify roles as needed
  member  = "serviceAccount:${element(var.project_owners, 0)}"
}