provider "google" {
 project     = var.project
 region      = var.location
 zone = var.zone
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_project_iam_member" "gcs-pubsub-publishing" {
  project = var.project
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_service_account" "account" {
  account_id   = "gcf-sa"
  display_name = "Test Service Account - used for both the cloud function and eventarc trigger in the test"
}

resource "google_project_iam_member" "invoking" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.gcs-pubsub-publishing]
}

resource "google_project_iam_member" "event-receiving" {
  project = var.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.invoking]
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

resource "google_storage_bucket" "this" {
  name = "${var.project}-upload"
  project = var.project
  location = var.location
  force_destroy = true
  uniform_bucket_level_access = true
  storage_class = "STANDARD"
}

resource "google_storage_bucket_object" "this" {
  name   = "detector.zip"
  bucket = google_storage_bucket.this.id
  source = "detector.zip"
}

resource "google_cloudfunctions2_function" "this" {
  depends_on = [
    google_project_iam_member.event-receiving
  ]

  name        = "detector-function"
  location    = var.location
  project     = var.project

  build_config {
    runtime     = "python311"
    entry_point = "main"

    source {
      storage_source {
        bucket = google_storage_bucket.this.id
        object = google_storage_bucket_object.this.name
      }
    }
  }

  service_config {
    min_instance_count             = 1
    max_instance_count             = 1
    available_memory    = "256M"
  }

  event_trigger {
    trigger_region = var.location
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.this.id
    retry_policy = "RETRY_POLICY_RETRY"
  }
}

resource "google_pubsub_subscription" "subscription" {
  name = "detector-subscription"
  topic = google_pubsub_topic.this.name
}

resource "google_pubsub_topic" "this" {
  name = "detector-topic"
}

resource "google_logging_project_sink" "startvm" {
  name        = "startvm"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${google_pubsub_topic.this.name}"
  filter      = "protoPayload.request.@type=\"type.googleapis.com/compute.instances.start\""

  unique_writer_identity = true
}

resource "google_logging_project_sink" "stopvm" {
  name        = "stopvm"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${google_pubsub_topic.this.name}"
  filter      = "protoPayload.request.@type=\"type.googleapis.com/compute.instances.stop\""

  unique_writer_identity = true
}

resource "google_eventarc_trigger" "this" {
    name = "eventarc-detector"
    location = var.location
    matching_criteria {
        attribute = "type"
        value = "google.cloud.pubsub.topic.v1.messagePublished"
    }
    destination {
        cloud_run_service {
            service = google_cloudfunctions2_function.this.name
            region = var.location
        }
    }
}
