variable "location" {
    type = string
    description = "Azure resource location"
}

variable "law_id" {
    type = string
    description = "Resource ID of the central log analytics workspace"
}

variable "webhook_name" {
    type = string
    description = "Name of the alert webhook"
}

variable "webhook_service_uri" {
    type = string
    description = "Link to the webhook receiver URL"
}

