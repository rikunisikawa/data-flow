variable "role_name" {
  description = "The name of the IAM role."
  type        = string
}

variable "assume_role_policy" {
  description = "The policy that grants an entity permission to assume the role."
  type        = string
}

variable "policies" {
  description = "A list of IAM policies to attach to the role."
  type = list(object({
    name    = string
    document = string
  }))
  default = []
}
