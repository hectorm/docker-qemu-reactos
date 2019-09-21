# ReactOS on Docker

A Docker image for the [ReactOS](https://www.reactos.org) operating system.

## Start an instance
```sh
docker run --detach \
  --name qemu-reactos \
  --restart on-failure:3 \
  --publish 127.0.0.1:6080:6080/tcp \
  --privileged --env QEMU_KVM=true \
  hectormolinero/qemu-reactos:latest
```
> The instance will be available through a web browser from: http://localhost:6080/vnc.html

## Environment variables
#### `QEMU_CPU`
Number of cores the VM is permitted to use (`2` by default).

#### `QEMU_RAM`
Amount of memory the VM is permitted to use (`1024M` by default).

#### `QEMU_DISK_SIZE`
VM disk size (`16G` by default).

#### `QEMU_DISK_FORMAT`
VM disk format (`qcow2` by default).

#### `QEMU_KEYBOARD`
VM keyboard layout (`en-us` by default).

#### `QEMU_NET_DEVICE`
VM network device (`e1000` by default).

#### `QEMU_BOOT_ORDER`
VM boot order (`cd` by default).

#### `QEMU_BOOT_MENU`
VM boot menu (`off` by default).

#### `QEMU_KVM`
Start QEMU in KVM mode (`false` by default).
> The `--privileged` option is required to use KVM in the container.

## License
See the [license](LICENSE.md) file.
