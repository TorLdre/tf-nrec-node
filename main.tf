## SSH key
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.name}-keys"
  region     = var.region
  public_key = file(var.ssh_public_key)
}

## Basic security group
resource "openstack_networking_secgroup_v2" "basic" {
  region      = var.region
  name        = "${var.name}_basic"
  description = "Security groups for allowing SSH and ICMP access"
}

# Allow ssh from IPv4 net
resource "openstack_networking_secgroup_rule_v2" "rule_ssh_access_ipv4" {
  count             = length(var.allow_ssh_from_v4)
  region            = var.region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.ssh_port
  port_range_max    = var.ssh_port
  remote_ip_prefix  = element(var.allow_ssh_from_v4, count.index)
  security_group_id = openstack_networking_secgroup_v2.basic.id
}

# Allow ssh from IPv6 net
resource "openstack_networking_secgroup_rule_v2" "rule_ssh_access_ipv6" {
  count             = length(var.allow_ssh_from_v6)
  region            = var.region
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = var.ssh_port
  port_range_max    = var.ssh_port
  remote_ip_prefix  = element(var.allow_ssh_from_v6, count.index)
  security_group_id = openstack_networking_secgroup_v2.basic.id
}

# Allow icmp from IPv4 net
resource "openstack_networking_secgroup_rule_v2" "rule_icmp_access_ipv4" {
  count             = length(var.allow_icmp_from_v4)
  region            = var.region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = element(var.allow_icmp_from_v4, count.index)
  security_group_id = openstack_networking_secgroup_v2.basic.id
}

# Allow icmp from IPv6 net
resource "openstack_networking_secgroup_rule_v2" "rule_icmp_access_ipv6" {
  count             = length(var.allow_icmp_from_v6)
  region            = var.region
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "ipv6-icmp"
  remote_ip_prefix  = element(var.allow_icmp_from_v6, count.index)
  security_group_id = openstack_networking_secgroup_v2.basic.id
}

# Get image id for image name
# this is only used if image_id is empty
data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

## Create node instance
resource "openstack_compute_instance_v2" "node" {
  count             = var.node_count
  name              = var.node_count > 1 ? "${format("${var.node_name}%03d", count.index + 1 + var.node_name_offset)}.${var.domain}" : "${var.node_name}.${var.domain}"
  image_id          = var.image_id != "" ? var.image_id : data.openstack_images_image_v2.image.id
  region            = var.region
  flavor_name       = var.flavor
  key_pair          = "${var.name}-keys"
  availability_zone = "${var.region}-${var.az}"
  security_groups   = concat(["default", "${var.name}_basic"], var.sec_group)

  network {
    name = var.network
  }
  metadata   = var.metadata
  depends_on = [openstack_networking_secgroup_v2.basic]

  user_data = var.user_data != null ? file(var.user_data) : null

  dynamic "scheduler_hints" {
    for_each = var.server_group
    content {
      group = scheduler_hints.value
    }
  }

}

## Volume
resource "openstack_blockstorage_volume_v3" "volume" {
  count       = var.volume_size > 0 ? var.node_count : 0
  region      = var.region
  name        = "${var.name}-${format("${var.volume_name}%03d", count.index + 1)}"
  size        = var.volume_size
  volume_type = var.volume_type
}

# Attach volume
resource "openstack_compute_volume_attach_v2" "volumes" {
  count       = var.volume_size > 0 ? var.node_count : 0
  region      = var.region
  instance_id = openstack_compute_instance_v2.node.*.id[count.index]
  volume_id   = openstack_blockstorage_volume_v3.volume.*.id[count.index]
}

