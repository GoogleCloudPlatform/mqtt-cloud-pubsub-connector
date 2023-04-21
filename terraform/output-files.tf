resource "local_file" "backend_configuration_file" {
  file_permission = "0644"
  filename        = "backend.tf"
  content = templatefile("templates/backend.tf.tpl", {
    bucket = module.terraform_backend_gcs_buckets.buckets[0].name
    prefix = "terraform/state"
  })
}
