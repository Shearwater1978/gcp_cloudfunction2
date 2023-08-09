provider "google" {
  project     = var.project
  region      = var.location
  zone        = var.zone
  credentials = var.gcp_credentials
}

resource "random_pet" "this" {
  length = 1
}

locals {
  prefix = random_pet.this.id
}

resource "google_service_account" "account" {
  account_id   = "${local.prefix}-gcf-sa"
  display_name = "Test service account ${local.prefix}-gcf-sa"
  project      = var.project
}

resource "google_project_iam_member" "admin" {
  project = var.project
  role    = "roles/pubsub.admin"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "editor" {
  project = var.project
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "publisher" {
  project = var.project
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_pubsub_topic" "this" {
  name = "${local.prefix}-${var.basename}-topic"
}

resource "google_pubsub_subscription" "subscription" {
  name  = "${local.prefix}-${var.basename}-subscription"
  topic = google_pubsub_topic.this.name

  retry_policy {
    minimum_backoff = "10s"
  }

  depends_on = [
    google_project_iam_member.admin,
    google_project_iam_member.editor,
    google_project_iam_member.publisher
  ]
}

resource "google_logging_project_sink" "startvm" {
  name        = "${local.prefix}-startvm"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${google_pubsub_topic.this.name}"

  filter = <<-filtercontent
    protoPayload.request.@type="type.googleapis.com/compute.instances.start"
  filtercontent

  unique_writer_identity = true
}

resource "google_logging_project_sink" "stopvm" {
  name        = "${local.prefix}-stopvm"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${google_pubsub_topic.this.name}"

  filter = <<-filtercontent
    protoPayload.request.@type="type.googleapis.com/compute.instances.stop"
  filtercontent

  unique_writer_identity = true
}
