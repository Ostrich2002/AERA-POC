# Terraform GCP Folder

This module facilitates the creation of multiple folders under a specified organization or parent folder in Google Cloud Platform (GCP). It uses a provided map of folders to automatically set up the desired folder structure within GCP.

## Requirements
These sections describe requirements for using this module.

### Software
- [Terraform](https://developer.hashicorp.com/terraform/install) v1.3+
- [Terraform Provider for GCP](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Service Account
A service account with the following roles must be used to provision the resources of this module:

- Folder Creator: `roles/resourcemanager.folderCreator`

### APIs
A project with the following APIs enabled must be used to host the resources of this module:

- Cloud Resource Manager API: `cloudresourcemanager.googleapis.com`

## Usage

Basic usage of this module is as follows:

```hcl
module "folders" {
    source  = "https://github.com/aera-jawed/tf-gcp-folder"

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
```

## Outputs
Here is the Sample output

```hcl
# Changes to Outputs:
  folder_ids = [
      [
          {
              "Folder1" = "folders/321487362833"
            },
          {
              "Folder2" = "folders/158313258908"
            },
        ],
      [
          {
              Sub_folder1 = "folders/334890287748"
            },
        ],
      [
          {
              Sub_folder21 = "folders/607453794231"
            },
          {
              Sub_folder21 = "folders/934851901892"
            },
        ],
    ]
```
