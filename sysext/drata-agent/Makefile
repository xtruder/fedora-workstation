VERSION := 3.9.0
ARCH := x86-64

build:
	-sudo rm -rf rootfs image.tar
	podman build -t drata-agent-sysext .
	podman save drata-agent-sysext -o image.tar
	mkdir rootfs
	tar -xOf image.tar --wildcards '*.tar' | sudo tar --preserve-permissions --same-owner -x -C rootfs/
	(cd rootfs; sudo setfiles -r . /etc/selinux/targeted/contexts/files/file_contexts . && sudo chcon --user=system_u --recursive .)
	sudo mkfs.erofs -zlz4 drata-agent-$(VERSION)-$(ARCH).raw rootfs

