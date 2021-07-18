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
		unzip \
	&& rm -rf /var/lib/apt/lists/*

# Download noVNC
ARG NOVNC_VERSION=v1.2.0
ARG NOVNC_TARBALL_URL=https://github.com/novnc/noVNC/archive/${NOVNC_VERSION}.tar.gz
ARG NOVNC_TARBALL_CHECKSUM=36c476b26df4684f1002e15c3d7e034c9e6ee4521e5fa8aac37309f954a07a01
RUN curl -Lo /tmp/novnc.tgz "${NOVNC_TARBALL_URL:?}"
RUN printf '%s' "${NOVNC_TARBALL_CHECKSUM:?}  /tmp/novnc.tgz" | sha256sum -c
RUN mkdir /tmp/novnc/ && tar -xzf /tmp/novnc.tgz --strip-components=1 -C /tmp/novnc/

# Download Websockify
ARG WEBSOCKIFY_VERSION=v0.9.0
ARG WEBSOCKIFY_TARBALL_URL=https://github.com/novnc/websockify/archive/${WEBSOCKIFY_VERSION}.tar.gz
ARG WEBSOCKIFY_TARBALL_CHECKSUM=6ebfec791dd78be6584fb5fe3bc27f02af54501beddf8457368699f571de13ae
RUN curl -Lo /tmp/websockify.tgz "${WEBSOCKIFY_TARBALL_URL:?}"
RUN printf '%s' "${WEBSOCKIFY_TARBALL_CHECKSUM:?}  /tmp/websockify.tgz" | sha256sum -c
RUN mkdir /tmp/websockify/ && tar -xzf /tmp/websockify.tgz --strip-components=1 -C /tmp/websockify/

# Download ReactOS ISO
ARG REACTOS_ISO_URL=https://downloads.sourceforge.net/project/reactos/ReactOS/0.4.14/ReactOS-0.4.14-RC-96-g08352ec-iso.zip
ARG REACTOS_ISO_CHECKSUM=e8ab9c83a4024013d04c0249fc4865e00484d54a69d40967d16ead40c4e62323
RUN curl -Lo /tmp/reactos.zip "${REACTOS_ISO_URL:?}"
RUN printf '%s' "${REACTOS_ISO_CHECKSUM:?}  /tmp/reactos.zip" | sha256sum -c
RUN unzip -p /tmp/reactos.zip 'ReactOS-*.iso' > /tmp/reactos.iso

##################################################
## "qemu-reactos" stage
##################################################

FROM docker.io/ubuntu:20.04 AS qemu-reactos

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		net-tools \
		procps \
		python3 \
		qemu-kvm \
		qemu-system-x86 \
		qemu-utils \
		runit \
	&& rm -rf /var/lib/apt/lists/*

# Environment
ENV QEMU_CPU=2
ENV QEMU_RAM=1024M
ENV QEMU_DISK_SIZE=16G
ENV QEMU_DISK_FORMAT=qcow2
ENV QEMU_KEYBOARD=en-us
ENV QEMU_NET_DEVICE=e1000
ENV QEMU_NET_OPTIONS=hostfwd=tcp::13389-:3389,hostfwd=tcp::15900-:5900
ENV QEMU_BOOT_ORDER=cd
ENV QEMU_BOOT_MENU=off
ENV QEMU_KVM=false

# Create some directories for QEMU
RUN mkdir -p /var/lib/qemu/iso/ /var/lib/qemu/images/

# Copy noVNC
COPY --from=build --chown=root:root /tmp/novnc/ /opt/novnc/

# Copy Websockify
COPY --from=build --chown=root:root /tmp/websockify/ /opt/novnc/utils/websockify/

# Copy ReactOS ISO
COPY --from=build --chown=root:root /tmp/reactos.iso /var/lib/qemu/iso/reactos.iso

# Copy services
COPY --chown=root:root ./scripts/service/ /etc/service/

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/

# VNC
EXPOSE 5900/tcp
# noVNC
EXPOSE 6080/tcp

CMD ["/usr/local/bin/container-foreground-cmd"]
