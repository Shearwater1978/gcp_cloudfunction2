Prerequsites:
- User should be login to the gcp console via `gcloud auth application-default login`
- Full path with json file name must be exported as variable `export TF_VAR_gcp_credentials="/%full_path_to_json/application_default_credentials.json"`


Before deploy env variable ```project``` must be exported or set explicitly in the file
myvar.tf

export TF_VAR_project=%project_name%
