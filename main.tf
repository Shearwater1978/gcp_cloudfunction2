provider "google" {
 project     = var.project
 region      = var.location
 zone = var.zone
}

resource "random_string" "this" {
  length = 6
  lower = true
  special = false
  upper = false
}

locals {
  uuid = random_string.this.result
}

resource "google_service_account" "account" {
  account_id   = "${local.uuid}-gcf-sa"
  display_name = "Test service account ${local.uuid}"
  project = var.project
}

resource "google_project_iam_member" "editor" {
  project = var.project
  role   = "roles/pubsub.editor"
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_iam_member" "publisher" {
  project = var.project
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_pubsub_topic" "this" {
  name = "${local.uuid}-detector-topic"
}

resource "google_pubsub_subscription" "subscription" {
  name = "${local.uuid}-detector-subscription"
  topic = "${google_pubsub_topic.this.name}"

  retry_policy {
    minimum_backoff = "10s"
  }

  depends_on = [
    google_project_iam_member.publisher
  ]
}

resource "google_logging_project_sink" "startvm" {
  name        = "${local.uuid}-startvm"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${google_pubsub_topic.this.name}"
  filter      = "protoPayload.request.@type=\"type.googleapis.com/compute.instances.start\""

  unique_writer_identity = true
}

resource "google_logging_project_sink" "stopvm" {
  name        = "${local.uuid}-stopvm"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${google_pubsub_topic.this.name}"
  filter      = "protoPayload.request.@type=\"type.googleapis.com/compute.instances.stop\""

  unique_writer_identity = true
}
