output "folder_ids" {
  value = [[for k, v in var.folder_map : module.folders[k].ids], [for i in local.sub_folders1_var : module.sub_folders1[i].ids], [for j in local.sub_folders2_var : module.sub_folders2[j].ids]]
}


#new addition for projects
# Output for project IDs and names
output "project_ids" {
  description = "The project names and their corresponding IDs"
  value = {
    for k, v in var.folder_map["aera-build-infra-services"]["US"] : k => module.projects[k].project_id
  }
}
output "project_names" {
  description = "The project names"
  value = {
    for k, v in var.folder_map["aera-build-infra-services"]["US"] : k => module.projects[k].name
  }
}

output "project_numbers" {
  description = "The project numbers"
  value = {
    for k, v in var.folder_map["aera-build-infra-services"]["US"] : k => module.projects[k].project_number
  }
}
