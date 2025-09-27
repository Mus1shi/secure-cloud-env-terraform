# Root variables.tf

# only one var here but critical for security
# this define the public IP (in CIDR format, ex: 141.135.52.137/32)
# it is used to restrict SSH access to the bastion
# always update this if ur IP change!
variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation (/32) for SSH access"
  type        = string
}
