variable "project_id" {
  type        = string
  description = "value"
  default     = "practice-413815"
}

variable "bucket_name" {
  type        = string
  description = "Name of storage bucket for backend"
  default     = "terra-bucket101"
}

variable "region" {
  type        = string
  description = "Default region"
  default     = "us-west1"
}
