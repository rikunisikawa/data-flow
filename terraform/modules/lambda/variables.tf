variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your Lambda function."
  type        = string
}

variable "runtime" {
  description = "The runtime for the Lambda function."
  type        = string
}

variable "architectures" {
  description = "The instruction set architecture for the Lambda function."
  type        = list(string)
  default     = ["x86_64"]
}

variable "memory_size" {
  description = "The amount of memory in MB your Lambda function has access to."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "The amount of time the Lambda function has to run in seconds."
  type        = number
  default     = 300
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem."
  type        = string
}

variable "role_arn" {
  description = "The ARN of the IAM role that Lambda assumes when it executes your function."
  type        = string
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum 5) to attach to your Lambda Function."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "A map of environment variables that are accessible from the Lambda function code."
  type        = map(string)
  default     = {}
}
