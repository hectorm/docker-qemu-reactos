# ReactOS on Docker

A Docker image for the [ReactOS](https://www.reactos.org) operating system.

## Start an instance
```sh
docker run --detach \
  --name qemu-reactos \
  --restart on-failure:3 \
  --publish 127.0.0.1:6080:6080/tcp \
  --env QEMU_VM_KVM=true --device /dev/kvm \
  docker.io/hectormolinero/qemu-reactos:latest
```
> The instance will be available through a web browser from: http://localhost:6080/vnc.html

## Environment variables
#### `QEMU_VM_CPU`
Number of cores the VM is permitted to use (`2` by default).

#### `QEMU_VM_RAM`
Amount of memory the VM is permitted to use (`1024M` by default).

#### `QEMU_VM_DISK_SIZE`
VM disk size (`16G` by default).

#### `QEMU_VM_DISK_FORMAT`
VM disk format (`qcow2` by default).

#### `QEMU_VM_KEYBOARD`
VM keyboard layout (`en-us` by default).

#### `QEMU_VM_NET_DEVICE`
VM network device (`e1000` by default).

#### `QEMU_VM_BOOT_ORDER`
VM boot order (`cd` by default).

#### `QEMU_VM_BOOT_MENU`
VM boot menu (`off` by default).

#### `QEMU_VM_KVM`
Start QEMU in KVM mode (`false` by default).
> The `--device /dev/kvm` option is required to use KVM in the container.

## License
See the [license](LICENSE.md) file.
