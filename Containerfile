FROM quay.io/centos-boot/fedora-bootc:eln
# Add cs-user
RUN useradd -ms /bin/bash cs-user
# Copy crowdstrike artifacts to tmp location
COPY crowdstrike /tmp/falcon
# Import GPG key
RUN rpm --import /tmp/falcon/falcon_sensor_gpg_key
# Clean up existing files in /opt/
RUN rm -rf /opt/*
# Install Falcon Sensor
RUN dnf install -y /tmp/falcon/falcon-sensor-7.11.0-16404.el9.x86_64.rpm && \ dnf clean all
# Create SSH configuration
RUN mkdir /usr/etc-system && \ echo 'AuthorizedKeysFile /usr/etc-system/%u.keys' >> /etc/ssh/sshd_config.d/30-auth-system.conf && \ echo 
    'AAAAB3NzaC1yc2EAAAADAQABAAACAQDmDZ4wVgaz2jV/QoRPtk0n+rBaDwozyl9aMmRB7dFbW/uSU+Ltimxc70x2/DtvVvLuX23BBX5M2RfCw>' > /usr/etc-system/root.keys && \ chmod 0600 
    /usr/etc-system/root.keys
# Start the Podman socket service at runtime
CMD ["systemctl", "start", "podman.socket"]
# Enable the Podman socket service to start on boot
RUN systemctl enable podman.socket
# Start falcon-sensor service
CMD ["systemctl", "start", "falcon-sensor"]
# Run falconctl command as cs-user with sudo privileges
USER cs-user RUN sudo /opt/CrowdStrike/falconctl -d -f --aid
