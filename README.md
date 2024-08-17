# ReactOS on Docker

A Docker image for the [ReactOS](https://www.reactos.org) operating system.

## Start an instance
```sh
docker run --detach \
  --name qemu-reactos \
  --device /dev/kvm \
  --publish 127.0.0.1:5900:5900/tcp \
  --publish 127.0.0.1:6080:6080/tcp \
  docker.io/hectorm/qemu-reactos:latest
```

> [!NOTE]
> The `--device /dev/kvm` option can only be used on Linux hosts, it can be removed on Windows and macOS hosts at a significant performance penalty.

The instance can be accessed from:
 * **VNC** (`5900/TCP`), without password.
 * **noVNC** (`6080/TCP`), http://127.0.0.1:6080/vnc.html
 * `docker exec -it qemu-reactos vmshell`

## Environment variables
#### `VM_CPU`
Number of cores the VM is permitted to use (`2` by default).

#### `VM_RAM`
Amount of memory the VM is permitted to use (`1024M` by default).

#### `VM_KEYBOARD`
VM keyboard layout (`en-us` by default).

#### `VM_KVM`
Start QEMU in KVM mode (`true` by default).
> The `--device /dev/kvm` option is required for this variable to take effect.

## License
See the [license](LICENSE.md) file.
