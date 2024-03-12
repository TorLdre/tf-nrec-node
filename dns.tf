## Find zone info if zone_name is set
data "openstack_dns_zone_v2" "hostname_zone" {
  count  = var.zone_name == null ? 0 : 1
  name   = "${var.zone_name}."
  type   = "PRIMARY"
  region = var.region
}

## Create hostname records for A and AAAA
resource "openstack_dns_recordset_v2" "ipv4_hostname" {
  count   = var.zone_name == null ? 0 : var.node_count
  region  = var.region
  zone_id = element(data.openstack_dns_zone_v2.hostname_zone.*.id, 0)
  name    = "${element(openstack_compute_instance_v2.node.*.name, count.index)}."
  ttl     = 600
  type    = "A"
  records = [
    element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)
  ]
  depends_on = [openstack_compute_instance_v2.node]
}

resource "openstack_dns_recordset_v2" "ipv6_hostname" {
  count   = var.zone_name == null ? 0 : var.node_count
  region  = var.region
  zone_id = element(data.openstack_dns_zone_v2.hostname_zone.*.id, 0)
  name    = "${element(openstack_compute_instance_v2.node.*.name, count.index)}."
  ttl     = 600
  type    = "AAAA"
  records = [
    trim(element(openstack_compute_instance_v2.node.*.access_ip_v6, count.index), "[]")
  ]
  depends_on = [openstack_compute_instance_v2.node]
}

resource "openstack_dns_recordset_v2" "CNAMEs" {
  count       = length(var.cnames)
  zone_id     = element(data.openstack_dns_zone_v2.hostname_zone.*.id, 0)
  name        = join("", [element(var.cnames, count.index), ".${var.zone_name}."])
  description = "CNAME for RAIL services"
  type        = "CNAME"
  records     = ["${element(openstack_compute_instance_v2.node.*.name, count.index)}."]
}

resource "openstack_dns_recordset_v2" "ipv4_record_workload_ingress_ip" {
  count       = var.wc_ingress == null ? 0 : 1
  zone_id     = element(data.openstack_dns_zone_v2.hostname_zone.*.id, 0)
  name        = "*.${var.zone_name}."
  description = "IPv4 ingress for workload cluster"
  type        = "A"
  records     = [tolist(var.wc_ingress, )[0]]
}

resource "openstack_dns_recordset_v2" "ipv6_record_workload_ingress_ip" {
  count       = var.wc_ingress == null ? 0 : 1
  zone_id     = element(data.openstack_dns_zone_v2.hostname_zone.*.id, 0)
  name        = "*.${var.zone_name}."
  description = "IPv4 ingress for workload cluster"
  type        = "AAAA"
  records     = [tolist(var.wc_ingress, )[1]]
}
