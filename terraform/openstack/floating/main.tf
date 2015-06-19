provider "openstack" {
  auth_url      = "${ var.auth_url }"
  tenant_id     = "${ var.tenant_id }"
  tenant_name   = "${ var.tenant_name }"
}

resource "openstack_compute_instance_v2" "control" {
  floating_ip = "${ element(openstack_compute_floatingip_v2.ms-control-floatip.*.address, count.index) }"
  # name                  = "${ var.instance_name }"
  name                  = "${lookup(var.instance_name, count.index)}"
  image_name            = "${ var.image_name }"
  flavor_name           = "${ var.flavor_name }"
  security_groups       = [ "${ var.security_groups }" ]
  network               = { uuid = "${ openstack_networking_network_v2.ms-network.id }" }
  metadata              = {
                            dc = "${var.datacenter}"
                            role = "control"
                          }
  count                 = "${ var.instance_count }"
}

resource "openstack_compute_floatingip_v2" "ms-control-floatip" {
  pool       = "${ var.floating_pool }"
  count      = "${ var.floating_ip_count }"
  depends_on = [ "openstack_networking_router_v2.ms-router",
                 "openstack_networking_network_v2.ms-network",
                 "openstack_networking_router_interface_v2.ms-router-interface" ]
}

resource "openstack_networking_network_v2" "ms-network" {
  name = "${ var.short_name }-network"
}

resource "openstack_networking_subnet_v2" "ms-subnet" {
  name          = "${ var.short_name }-subnet"
  network_id    = "${ openstack_networking_network_v2.ms-network.id }"
  cidr          = "${ var.subnet_cidr }"
  ip_version    = "${ var.ip_version }"
}

resource "openstack_networking_router_v2" "ms-router" {
  name             = "${ var.short_name }-router"
  external_gateway = "${ var.external_net_id }"
}

resource "openstack_networking_router_interface_v2" "ms-router-interface" {
  router_id = "${ openstack_networking_router_v2.ms-router.id }"
  subnet_id = "${ openstack_networking_subnet_v2.ms-subnet.id }"
}
