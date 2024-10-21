module "google-folders" {
  source = "../modules/google-folders"

  org_id = "11122233344455"
  folder_map = {
    "Folder1" : [],
    "Folder2" : {
      "Sub_folder1" : {
        "Sub_folder21" : [],
        "Sub_folder22" : []
      }
    }
  }

}
