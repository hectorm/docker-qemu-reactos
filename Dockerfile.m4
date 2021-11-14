m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

FROM docker.io/ubuntu:20.04 AS build

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		genisoimage \
		p7zip-full \
		qemu-system-x86 \
		qemu-utils \
	&& rm -rf /var/lib/apt/lists/*

# Download noVNC
ARG NOVNC_VERSION=v1.3.0
ARG NOVNC_TARBALL_URL=https://github.com/novnc/noVNC/archive/${NOVNC_VERSION}.tar.gz
ARG NOVNC_TARBALL_CHECKSUM=ee8f91514c9ce9f4054d132f5f97167ee87d9faa6630379267e569d789290336
RUN curl -Lo /tmp/novnc.tgz "${NOVNC_TARBALL_URL:?}"
RUN printf '%s' "${NOVNC_TARBALL_CHECKSUM:?}  /tmp/novnc.tgz" | sha256sum -c
RUN mkdir /tmp/novnc/ && tar -xzf /tmp/novnc.tgz --strip-components=1 -C /tmp/novnc/

# Download Websockify
ARG WEBSOCKIFY_VERSION=v0.10.0
ARG WEBSOCKIFY_TARBALL_URL=https://github.com/novnc/websockify/archive/${WEBSOCKIFY_VERSION}.tar.gz
ARG WEBSOCKIFY_TARBALL_CHECKSUM=7bd99b727e0be230f6f47f65fbe4bd2ae8b2aa3568350148bdf5cf440c4c6b4a
RUN curl -Lo /tmp/websockify.tgz "${WEBSOCKIFY_TARBALL_URL:?}"
RUN printf '%s' "${WEBSOCKIFY_TARBALL_CHECKSUM:?}  /tmp/websockify.tgz" | sha256sum -c
RUN mkdir /tmp/websockify/ && tar -xzf /tmp/websockify.tgz --strip-components=1 -C /tmp/websockify/

# Download Samba for ReactOS
ARG SAMBA_EXE_URL=https://svn.reactos.org/packages/samba-for-ReactOSv1.3.exe
ARG SAMBA_EXE_CHECKSUM=c3f55cd7a4069cd682cbdca3954c425f6657e3a1aba786e3d1559448e9f849a3
RUN curl -Lo /tmp/samba.exe "${SAMBA_EXE_URL:?}"
RUN printf '%s' "${SAMBA_EXE_CHECKSUM:?}  /tmp/samba.exe" | sha256sum -c

# Download BusyBox for Windows
ARG BUSYBOX_EXE_URL=https://frippery.org/files/busybox/busybox-w32-FRP-4487-gd239d2d52.exe
ARG BUSYBOX_EXE_CHECKSUM=35e2b0db6d57a045188b9afc617aae52a6c8e2aa0205256c049f3537a48f879b
RUN curl -Lo /tmp/busybox.exe "${BUSYBOX_EXE_URL:?}"
RUN printf '%s' "${BUSYBOX_EXE_CHECKSUM:?}  /tmp/busybox.exe" | sha256sum -c

# Download ncat for Windows
ARG NCAT_ZIP_URL=https://nmap.org/dist/ncat-portable-5.59BETA1.zip
ARG NCAT_ZIP_CHECKSUM=9cdc2e688410f4563af7002d8dfa3f8a5710f15f6d409be2cab4e87890c91d1c
RUN curl -Lo /tmp/ncat.zip "${NCAT_ZIP_URL:?}"
RUN printf '%s' "${NCAT_ZIP_CHECKSUM:?}  /tmp/ncat.zip" | sha256sum -c

# Download and install ReactOS
ARG REACTOS_ISO_URL=https://downloads.sourceforge.net/project/reactos/ReactOS/0.4.14/ReactOS-0.4.14-RC-118-gfef1907-iso.zip
ARG REACTOS_ISO_CHECKSUM=751984454d54f16d39b02e4cfa88ce8adb4a5e666e985a137257fc9980047d65
RUN curl -Lo /tmp/reactos.zip "${REACTOS_ISO_URL:?}"
RUN printf '%s' "${REACTOS_ISO_CHECKSUM:?}  /tmp/reactos.zip" | sha256sum -c
RUN 7z e /tmp/reactos.zip -so '*.iso' > /tmp/reactos.iso \
	&& 7z x /tmp/reactos.iso -o/tmp/reactos/ \
	&& rm -f /tmp/reactos.iso
COPY --chown=root:root ./data/iso/ /tmp/reactos/
RUN cp /tmp/samba.exe /tmp/reactos/reactos/3rdParty/samba.exe
RUN cp /tmp/busybox.exe /tmp/reactos/reactos/3rdParty/busybox.exe
RUN 7z e /tmp/ncat.zip -so '**/*.exe' > /tmp/reactos/reactos/3rdParty/ncat.exe
RUN mkisofs -no-emul-boot -iso-level 4 -eltorito-boot loader/isoboot.bin -o /tmp/reactos.iso /tmp/reactos/ \
	&& qemu-img create -f qcow2 /tmp/reactos.qcow2 128G \
	&& timeout 900 qemu-system-x86_64 \
		-machine pc -smp 2 -m 512M -accel tcg \
		-serial stdio -device VGA -display none \
		-device e1000,netdev=n0 -netdev user,id=n0,restrict=on \
		-drive file=/tmp/reactos.qcow2,index=0,media=disk,format=qcow2 \
		-drive file=/tmp/reactos.iso,index=2,media=cdrom,format=raw \
		-boot order=cd,menu=off -usb -device usb-tablet

##################################################
## "base" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:20.04]], [[FROM docker.io/ubuntu:20.04]]) AS base
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		net-tools \
		netcat-openbsd \
		procps \
		python3 \
		qemu-kvm \
		qemu-system-x86 \
		qemu-utils \
		rlwrap \
		runit \
		samba \
		tini \
	&& rm -rf /var/lib/apt/lists/*

# Environment
ENV VM_CPU=2
ENV VM_RAM=1024M
ENV VM_KEYBOARD=en-us
ENV VM_NET_GUESTFWD_OPTIONS=guestfwd=tcp:10.0.2.254:445-cmd:"nc 127.0.0.1 445"
ENV VM_NET_HOSTFWD_OPTIONS=hostfwd=tcp::2323-:23,hostfwd=tcp::5151-:51,hostfwd=tcp::3389-:3389
ENV VM_NET_EXTRA_OPTIONS=
ENV VM_KVM=true
ENV SVDIR=/etc/service/

# Copy noVNC
COPY --from=build --chown=root:root /tmp/novnc/ /opt/novnc/

# Copy Websockify
COPY --from=build --chown=root:root /tmp/websockify/ /opt/novnc/utils/websockify/

# Copy ReactOS disk
COPY --from=build --chown=root:root /tmp/reactos.qcow2 /var/lib/qemu/image/reactos.qcow2

# Copy Samba config
COPY --chown=root:root ./config/samba/ /etc/samba/
RUN find /etc/samba/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/samba/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy services
COPY --chown=root:root ./scripts/service/ /etc/service/
RUN find /etc/service/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/service/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

# Copy bin scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/
RUN find /usr/local/bin/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /usr/local/bin/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/container-init"]

##################################################
## "test" stage
##################################################

FROM base AS test

RUN if [ "$(uname -m)" = 'x86_64' ]; then \
		container-init & \
		printf '%s\n' 'The quick brown fox jumps over the lazy dog' > /mnt/in || exit 1; \
		printf '%s\n' '@echo off & smbclient -c "get /in C:/local; quit" //10.0.2.254/share noop & exit' | timeout 900 vmshell || exit 1; \
		printf '%s\n' '@echo off & smbclient -c "put C:/local /out; quit" //10.0.2.254/share noop & exit' | timeout 120 vmshell || exit 1; \
		cmp -s /mnt/in /mnt/out || exit 1; \
	fi

##################################################
## "main" stage
##################################################

FROM base AS main

# Dummy instruction so BuildKit does not skip the test stage
RUN --mount=type=bind,from=test,source=/mnt/,target=/mnt/
