VERSION := 2.3.0-8
ARCH := x86-64

build: check-token
	-sudo rm -rf rootfs image.tar
	podman build -t jcagent-sysext --build-arg=TOKEN=$(TOKEN) .
	podman save jcagent-sysext -o image.tar
	mkdir rootfs
	tar -xOf image.tar --wildcards '*.tar' | sudo tar --preserve-permissions --same-owner -x -C rootfs/
	(cd rootfs; sudo setfiles -r . /etc/selinux/targeted/contexts/files/file_contexts . && sudo chcon --user=system_u --recursive .)
	sudo mkfs.erofs -zlz4 jcagent-$(VERSION)-$(ARCH).raw rootfs

check-token:
ifndef TOKEN
	$(error TOKEN is undefined)
endif

