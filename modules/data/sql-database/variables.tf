variable "name" {
  description = "Name."
  type        = string
}

variable "server_id" {
  description = "Server id."
  type        = string
}

variable "tags" {
  description = "Tags."
  type        = map(string)
}
