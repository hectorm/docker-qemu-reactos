# syntax=docker.io/docker/dockerfile:1
# check=skip=FromPlatformFlagConstDisallowed

m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

FROM --platform=linux/amd64 docker.io/ubuntu:26.04 AS build

SHELL ["/bin/sh", "-euc"]

# Install system packages
RUN <<-EOF
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends \
		7zip \
		binutils-mingw-w64-i686 \
		ca-certificates \
		curl \
		gcc-mingw-w64-i686 \
		genisoimage \
		make \
		qemu-system-x86 \
		qemu-utils
	rm -rf /var/lib/apt/lists/*
EOF

# Download noVNC
ARG NOVNC_VERSION=v1.7.0
ARG NOVNC_TARBALL_URL=https://github.com/novnc/noVNC/archive/${NOVNC_VERSION}.tar.gz
ARG NOVNC_TARBALL_CHECKSUM=b1003a11b6e6e8d8f7f5e5586daae7f8ca651d8aee0aa155ff9ac841c48f52c6
RUN <<-EOF
	curl -Lo /tmp/novnc.tgz "${NOVNC_TARBALL_URL:?}"
	printf '%s' "${NOVNC_TARBALL_CHECKSUM:?}  /tmp/novnc.tgz" | sha256sum -c
	mkdir /tmp/novnc/ && tar -xzf /tmp/novnc.tgz --strip-components=1 -C /tmp/novnc/
EOF

# Download Websockify
ARG WEBSOCKIFY_VERSION=v0.13.0
ARG WEBSOCKIFY_TARBALL_URL=https://github.com/novnc/websockify/archive/${WEBSOCKIFY_VERSION}.tar.gz
ARG WEBSOCKIFY_TARBALL_CHECKSUM=b6413e364efd04f3c92ec8c17747e3c4adc20157c2ef1c5d019a26d944a46df8
RUN <<-EOF
	curl -Lo /tmp/websockify.tgz "${WEBSOCKIFY_TARBALL_URL:?}"
	printf '%s' "${WEBSOCKIFY_TARBALL_CHECKSUM:?}  /tmp/websockify.tgz" | sha256sum -c
	mkdir /tmp/websockify/ && tar -xzf /tmp/websockify.tgz --strip-components=1 -C /tmp/websockify/
EOF

# Download and build srvany-ng
ARG SRVANY_NG_TARBALL_URL=https://github.com/hectorm/srvany-ng/archive/refs/tags/v1.1.tar.gz
ARG SRVANY_NG_TARBALL_CHECKSUM=79707e1c8dca927178a316a16a2c87e60a40f74e0c50b15c4d538e5c7ae5538f
RUN <<-EOF
	curl -Lo /tmp/srvany-ng.tgz "${SRVANY_NG_TARBALL_URL:?}"
	printf '%s' "${SRVANY_NG_TARBALL_CHECKSUM:?}  /tmp/srvany-ng.tgz" | sha256sum -c
	mkdir /tmp/srvany-ng/ && tar -xzf /tmp/srvany-ng.tgz --strip-components=1 -C /tmp/srvany-ng/
	make -C /tmp/srvany-ng/ build
EOF

# Download ncat
ARG NCAT_ZIP_URL=https://nmap.org/dist/ncat-portable-5.59BETA1.zip
ARG NCAT_ZIP_CHECKSUM=9cdc2e688410f4563af7002d8dfa3f8a5710f15f6d409be2cab4e87890c91d1c
RUN <<-EOF
	curl -Lo /tmp/ncat.zip "${NCAT_ZIP_URL:?}"
	printf '%s' "${NCAT_ZIP_CHECKSUM:?}  /tmp/ncat.zip" | sha256sum -c
	7z e /tmp/ncat.zip -so '**/*.exe' > /tmp/ncat.exe
EOF

# Download Samba
ARG SAMBA_EXE_URL=https://svn.reactos.org/packages/samba-for-ReactOSv1.3.exe
ARG SAMBA_EXE_CHECKSUM=c3f55cd7a4069cd682cbdca3954c425f6657e3a1aba786e3d1559448e9f849a3
RUN <<-EOF
	curl -Lo /tmp/samba.exe "${SAMBA_EXE_URL:?}"
	printf '%s' "${SAMBA_EXE_CHECKSUM:?}  /tmp/samba.exe" | sha256sum -c
EOF

# Download BusyBox
ARG BUSYBOX_EXE_URL=https://frippery.org/files/busybox/busybox-w32-FRP-6075-g169694ebd.exe
ARG BUSYBOX_EXE_CHECKSUM=7bfee530965315665044e6e01db58125f2763c8a39c2e72ba1a6beb6923e0e1f
RUN <<-EOF
	curl -Lo /tmp/busybox.exe "${BUSYBOX_EXE_URL:?}"
	printf '%s' "${BUSYBOX_EXE_CHECKSUM:?}  /tmp/busybox.exe" | sha256sum -c
EOF

# Download and install ReactOS
ARG REACTOS_ISO_URL=https://downloads.sourceforge.net/reactos/ReactOS-0.4.16-i386.zip
ARG REACTOS_ISO_CHECKSUM=e5851510cf5b79ef51a76b8155dd5ef7faca1155f44d0a1d41c35b77ece4ce2a
RUN <<-EOF
	curl -Lo /tmp/reactos.zip "${REACTOS_ISO_URL:?}"
	printf '%s' "${REACTOS_ISO_CHECKSUM:?}  /tmp/reactos.zip" | sha256sum -c
	7z e /tmp/reactos.zip -so '*.iso' > /tmp/reactos.iso
	7z x /tmp/reactos.iso -o/tmp/reactos/
	rm -f /tmp/reactos.zip /tmp/reactos.iso
EOF
COPY --chown=root:root ./data/iso/ /tmp/reactos/
RUN <<-EOF
	install -D /tmp/srvany-ng/srvany-ng.exe /tmp/reactos/i386/3rdParty/srvany-ng.exe
	install -D /tmp/ncat.exe /tmp/reactos/i386/3rdParty/ncat.exe
	install -D /tmp/samba.exe /tmp/reactos/i386/3rdParty/samba.exe
	install -D /tmp/busybox.exe /tmp/reactos/i386/3rdParty/busybox.exe
	sed -i 's/^DefaultOS=.*\r$/DefaultOS=Setup\r/' /tmp/reactos/freeldr.ini
	grep -q '^DefaultOS=Setup' /tmp/reactos/freeldr.ini
EOF
RUN <<-EOF
	mkisofs -no-emul-boot -iso-level 4 -eltorito-boot loader/isoboot.bin -o /tmp/reactos.iso /tmp/reactos/
	qemu-img create -f qcow2 /tmp/reactos.qcow2 128G
	timeout 900 qemu-system-x86_64 \
		-machine pc -smp 2 -m 512M -accel tcg \
		-device VGA -display none -serial stdio \
		-device e1000,netdev=n0 -netdev user,id=n0,ipv4=on,ipv6=off,net=10.0.2.0/24,host=10.0.2.2,dns=10.0.2.3,dhcpstart=10.0.2.15,restrict=on \
		-device ide-hd,id=disk0,bus=ide.0,drive=disk0 -blockdev driver=qcow2,node-name=disk0,file.driver=file,file.filename=/tmp/reactos.qcow2 \
		-device ide-cd,id=cd0,bus=ide.1,drive=cd0 -blockdev driver=raw,node-name=cd0,file.driver=file,file.filename=/tmp/reactos.iso,read-only=on \
		-boot order=cd,menu=off \
		-usb -device usb-tablet
EOF

##################################################
## "base" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:26.04]], [[FROM docker.io/ubuntu:26.04]]) AS base

SHELL ["/bin/sh", "-euc"]

# Install system packages
RUN <<-EOF
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends \
		catatonit \
		net-tools \
		netcat-openbsd \
		procps \
		python3 \
		qemu-system-x86 \
		qemu-utils \
		rlwrap \
		runit \
		samba
	rm -rf /var/lib/apt/lists/*
EOF

# Environment
ENV VM_CPU=2
ENV VM_RAM=1024M
ENV VM_KEYBOARD=en-us
ENV VM_NET_EXTRA_OPTIONS=
ENV VM_KVM=true
ENV SVDIR=/etc/service/

# Copy noVNC
COPY --from=build --chown=root:root /tmp/novnc/ /opt/novnc/

# Copy Websockify
COPY --from=build --chown=root:root /tmp/websockify/ /opt/novnc/utils/websockify/

# Copy ReactOS disk
COPY --from=build --chown=root:root /tmp/reactos.qcow2 /var/lib/qemu/disk/reactos.qcow2

# Copy Samba config
COPY --chown=root:root --chmod=a+rX,u+w,go-w ./config/samba/ /etc/samba/

# Copy services
COPY --chown=root:root --chmod=0755 ./scripts/service/ /etc/service/

# Copy bin scripts
COPY --chown=root:root --chmod=0755 ./scripts/bin/ /usr/local/bin/

ENTRYPOINT ["/usr/bin/catatonit", "--", "/usr/local/bin/container-init"]

##################################################
## "test" stage
##################################################

FROM base AS test

ARG BUILDARCH
ARG TARGETARCH
RUN <<-EOF
	if [ "${BUILDARCH:?}" = "${TARGETARCH:?}" ]; then
		container-init &
		printf '%s\n' 'The quick brown fox jumps over the lazy dog' > /mnt/in || exit 1
		printf '%s\n' '@echo off & smbclient -c "get /in C:/local; quit" //10.0.2.2/share noop & exit' | timeout 900 vmshell || exit 1
		printf '%s\n' '@echo off & smbclient -c "put C:/local /out; quit" //10.0.2.2/share noop & exit' | timeout 120 vmshell || exit 1
		cmp -s /mnt/in /mnt/out || exit 1
	fi
EOF

##################################################
## "main" stage
##################################################

FROM base AS main

# Dummy instruction so BuildKit does not skip the test stage
RUN --mount=type=bind,from=test,source=/mnt/,target=/mnt/
