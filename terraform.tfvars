libvirt_uri = "qemu+ssh://root@labserver/system?socket=/var/run/libvirt/libvirt-sock"
#libvirt_volume_source = "http://download.opensuse.org/distribution/leap/15.2/appliances/openSUSE-Leap-15.2-JeOS.x86_64-OpenStack-Cloud.qcow2"
libvirt_volume_source = "http://labserver/appliances/openSUSE-Leap-15.2-JeOS.x86_64-OpenStack-Cloud.qcow2"
instance_name = "instance"
ssh_public_key = "/Users/Geronimo/.ssh/id_rsa.pub"
number_of_instances = 3
dhcp = false
network_address = "172.18.1.0/24"
