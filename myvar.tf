variable project {
  type        = string
  default     = ""
  description = "Project name"
}

variable zone {
  type        = string
  default     = ""
  description = "Zone"
}

variable location {
  type        = string
  default     = ""
  description = "Region"
}

variable basename {
  type        = string
  default     = "detector"
  description = "basename for each resource"
}

variable gcp_credentials {}