FROM ubuntu:18.04

# Environment
ENV QEMU_CPU=2
ENV QEMU_RAM=1024M
ENV QEMU_DISK_SIZE=16G
ENV QEMU_DISK_FORMAT=qcow2
ENV QEMU_KEYBOARD=en-us
ENV QEMU_KVM=false

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		net-tools \
		novnc \
		qemu-kvm \
		qemu-system-x86 \
		qemu-utils \
		runit \
		unzip \
	&& rm -rf /var/lib/apt/lists/*

# Create data directories
RUN mkdir -p /var/lib/qemu/images/ /var/lib/qemu/iso/

# Download ReactOS ISO
ARG REACTOS_ISO_URL=https://github.com/reactos/reactos/releases/download/0.4.10-release/ReactOS-0.4.10-iso.zip
ARG REACTOS_ISO_CHECKSUM=6e7b80a8d89adf1ed73a4733227d1ecf368bb237fafc322b9fb319a737dcd061
RUN mkdir /tmp/reactos/ \
	&& curl -Lo /tmp/reactos/reactos.zip "${REACTOS_ISO_URL}" \
	&& echo "${REACTOS_ISO_CHECKSUM}  /tmp/reactos/reactos.zip" | sha256sum -c \
	&& unzip /tmp/reactos/reactos.zip -d /tmp/reactos/ \
	&& mv /tmp/reactos/*.iso /var/lib/qemu/iso/reactos.iso \
	&& rm -rf /tmp/reactos/

# Copy services
COPY --chown=root:root scripts/service/ /etc/service/

# Copy scripts
COPY --chown=root:root scripts/bin/ /usr/local/bin/

# Expose noVNC port
EXPOSE 6080/tcp

CMD ["/usr/local/bin/docker-foreground-cmd"]
