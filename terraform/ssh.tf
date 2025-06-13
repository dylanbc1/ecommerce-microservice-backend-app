# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/ssh-key"
  file_permission = "0600"
}

# Save public key to local file
resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.module}/ssh-key.pub"
  file_permission = "0644"
}
