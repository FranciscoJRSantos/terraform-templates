# Description: Infrastructure as Code for the Hetzner Cloud

# Define the variables
variable "application_name" {
  default = "application"
}

variable "hcloud_token" {
  sensitive = true # Requires terraform >= 0.14
}

variable "server_size" {
  default = "cx11"
}

variable "server_image" {
  default = "debian-11"
}

variable "server_location" {
  default = "nbg1"
}

variable "ssh_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "linode_token" {
  sensitive = true # Requires terraform >= 0.14
}

############### Hetzner Cloud ###############
# Define the Hetzner Cloud Provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.38.2"
    }

    linode = {
      source = "linode/linode"
      version = "1.30.0"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Create a SSH key
resource "hcloud_ssh_key" "web-key" {
  name       = "${var.application_name}-key"
  public_key = file(var.ssh_key_path)
}


# Create the firewall
resource "hcloud_firewall" "web-firewall" {
  name = "${var.application_name}-firewall"

  # Allow SSH
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow ICMP
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

    # Allow HTTP and HTTPS
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# Create a server
resource "hcloud_server" "web_server" {
  name         = "${var.application_name}-node1"
  image        = var.server_image
  server_type  = var.server_size
  location     = var.server_location
  ssh_keys     = [hcloud_ssh_key.web-key.id]
  firewall_ids = [hcloud_firewall.web-firewall.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}
############### Hetzner Cloud ###############

################ Linode ################
# Configure the Linode Provider
provider "linode" {
  token = var.linode_token
}

# Create a Linode Cluster
data "linode_object_storage_cluster" "web-cluster" {
  id = "eu-central-1"
}

# Create a linode bucket
resource "linode_object_storage_bucket" "web-bucket" {
  cluster = data.linode_object_storage_cluster.web-cluster.id
  label = "${var.application_name}-bucket"
}
################ Linode ################

################ Outputs ###############
# Output the Ip of the web_server
output "web_server_ip" {
  value = hcloud_server.web_server.ipv4_address
}
