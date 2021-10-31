# ReactOS on Docker

A Docker image for the [ReactOS](https://www.reactos.org) operating system.

## Start an instance
```sh
docker run --detach \
  --name qemu-reactos \
  --publish 127.0.0.1:6080:6080/tcp \
  --env VM_KVM=true --device /dev/kvm \
  docker.io/hectormolinero/qemu-reactos:latest
```

> The instance can be accessed from:
> * 6080/TCP (noVNC): http://127.0.0.1:6080/vnc.html

## Environment variables
#### `VM_CPU`
Number of cores the VM is permitted to use (`2` by default).

#### `VM_RAM`
Amount of memory the VM is permitted to use (`1024M` by default).

#### `VM_DISK_SIZE`
VM disk size (`16G` by default).

#### `VM_KEYBOARD`
VM keyboard layout (`en-us` by default).

#### `VM_BOOT_ORDER`
VM boot order (`cd` by default).

#### `VM_KVM`
Start QEMU in KVM mode (`false` by default).
> The `--device /dev/kvm` option is required to use KVM in the container.

## License
See the [license](LICENSE.md) file.
