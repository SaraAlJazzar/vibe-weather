terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "deploy" {
  name       = "vibe-weather-deploy"
  public_key = var.ssh_public_key
}

# Minimum spec: CX22 (2 vCPU, 4GB) or CX11 if available — ~€4-5/mo
resource "hcloud_server" "app" {
  name        = "vibe-weather"
  image       = "ubuntu-24.04"
  server_type = "cx22"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.deploy.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    runcmd:
      - curl -fsSL https://get.docker.com | sh
      - usermod -aG docker root
      - apt-get install -y docker-compose-plugin ufw iputils-ping traceroute
      - ufw allow OpenSSH
      - ufw allow 80/tcp
      - ufw allow 443/tcp
      - ufw --force enable
      - mkdir -p /opt/vibe-weather/nginx/conf.d
  EOF
}

output "server_ip" {
  value       = hcloud_server.app.ipv4_address
  description = "Public IP — point browser here on port 80"
}

output "server_name" {
  value = hcloud_server.app.name
}
