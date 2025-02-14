variable "regions" {
  type        = list(string)
  description = "AWS regions where resources will be created"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
}
