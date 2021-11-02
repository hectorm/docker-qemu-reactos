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

# Download ReactOS ISO
ARG REACTOS_ISO_URL=https://downloads.sourceforge.net/project/reactos/ReactOS/0.4.14/ReactOS-0.4.14-RC-117-g5e81087-iso.zip
ARG REACTOS_ISO_CHECKSUM=ec2776422ed45f8ee7488030eadd7ea40b4276cee04c5e5e5a3f1a5a68c978a7
RUN curl -Lo /tmp/reactos.zip "${REACTOS_ISO_URL:?}"
RUN printf '%s' "${REACTOS_ISO_CHECKSUM:?}  /tmp/reactos.zip" | sha256sum -c
RUN 7z e /tmp/reactos.zip -so '*.iso' > /tmp/reactos.iso \
	&& 7z x /tmp/reactos.iso -o/tmp/reactos/ \
	&& rm -f /tmp/reactos.iso
COPY --chown=root:root ./data/iso/ /tmp/reactos/
RUN mkisofs -no-emul-boot -iso-level 4 -eltorito-boot loader/isoboot.bin -o /tmp/reactos.iso /tmp/reactos/ \
	&& qemu-img create -f qcow2 /tmp/reactos.qcow2 124G \
	&& timeout 900 qemu-system-x86_64 \
		-accel tcg -smp 2 -m 512 -serial stdio -display none \
		-drive file=/tmp/reactos.qcow2,index=0,media=disk,format=qcow2 \
		-drive file=/tmp/reactos.iso,index=2,media=cdrom,format=raw \
		-boot order=cd,menu=off \
		-netdev user,id=n0 -device e1000,netdev=n0

##################################################
## "main" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:20.04]], [[FROM docker.io/ubuntu:20.04]]) AS main
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
		runit \
		tini \
	&& rm -rf /var/lib/apt/lists/*

# Environment
ENV VM_CPU=2
ENV VM_RAM=1024M
ENV VM_KEYBOARD=en-us
ENV VM_NET_OPTIONS=hostfwd=tcp::13389-:3389,hostfwd=tcp::15900-:5900
ENV VM_KVM=true
ENV SVDIR=/etc/service/

# Copy noVNC
COPY --from=build --chown=root:root /tmp/novnc/ /opt/novnc/

# Copy Websockify
COPY --from=build --chown=root:root /tmp/websockify/ /opt/novnc/utils/websockify/

# Copy ReactOS disk
COPY --from=build --chown=root:root /tmp/reactos.qcow2 /var/lib/qemu/reactos.qcow2

# Copy services
COPY --chown=root:root ./scripts/service/ /etc/service/
RUN find /etc/service/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/service/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

# Copy bin scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/
RUN find /usr/local/bin/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /usr/local/bin/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/container-init"]
