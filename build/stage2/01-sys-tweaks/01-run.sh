#!/bin/bash -e

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	sed -i -Ee 's/^#?[[:blank:]]*PubkeyAuthentication[[:blank:]]*no[[:blank:]]*$/PubkeyAuthentication yes/ s/^#?[[:blank:]]*PasswordAuthentication[[:blank:]]*yes[[:blank:]]*$/PasswordAuthentication no/' "${ROOTFS_DIR}"/etc/ssh/sshd_config
fi

on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi

# Disable cloud-init services (not needed for dedicated HDMI tester)
# This saves ~15 seconds of boot time
systemctl disable cloud-init.service || true
systemctl disable cloud-init-local.service || true
systemctl disable cloud-config.service || true
systemctl disable cloud-final.service || true
systemctl mask cloud-init.service || true
systemctl mask cloud-init-local.service || true
systemctl mask cloud-config.service || true
systemctl mask cloud-final.service || true
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	echo "leaving QEMU mode"
fi


on_chroot <<- EOF
	# Insert SD card resizing here if specified

	for GRP in input spi i2c gpio netdev render; do
		groupadd -f -r "\$GRP"
	done
	for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev render; do
		adduser $FIRST_USER_NAME \$GRP
	done
EOF

if [ -f "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd" ]; then
	sed -i "s/^pi /$FIRST_USER_NAME /" "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"
fi

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

# Remove SSH host keys for security (will be regenerated on first boot)
rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*

# Install and enable SSH key regeneration service for first boot
install -m 644 files/regenerate-ssh-keys.service "${ROOTFS_DIR}/etc/systemd/system/regenerate-ssh-keys.service"
on_chroot << EOF
systemctl enable regenerate-ssh-keys.service
EOF

sed -i 's/^FONTFACE=.*/FONTFACE=""/;s/^FONTSIZE=.*/FONTSIZE=""/' "${ROOTFS_DIR}/etc/default/console-setup"
sed -i "s/PLACEHOLDER//" "${ROOTFS_DIR}/etc/default/keyboard"
on_chroot << EOF
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration console-setup
EOF

if [ -e "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" ]; then
	sed -i 's/^#\?publish-workstation=.*/publish-workstation=yes/' "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf"
fi

# Set timezone to UTC
rm "${ROOTFS_DIR}/etc/localtime"
chroot "${ROOTFS_DIR}" ln -s /usr/share/zoneinfo/UTC /etc/localtime

# Enable console autologin for user 'pi'
# This is the standard method for Raspberry Pi OS.
# It creates a systemd override for getty@tty1.service.
on_chroot << EOF
raspi-config nonint do_boot_behaviour B2
EOF
