#!/bin/bash

# Generate new SSH fingerprint
ssh-keygen -f /etc/ssh/keys/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f /etc/ssh/keys/ssh_host_dsa_key -N '' -t dsa
ssh-keygen -f /etc/ssh/keys/ssh_host_ecdsa_key -N '' -t ecdsa
ssh-keygen -f /etc/ssh/keys/ssh_host_ed25519_key -N '' -t ed25519

# SSHD settings
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#PrintMotd .*/PrintMotd no/' /etc/ssh/sshd_config
sed -i 's/^#PermitUserEnvironment .*/PermitUserEnvironment yes/' /etc/ssh/sshd_config
sed -i 's/^#ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveInterval .*/ClientAliveInterval 120/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax .*/ClientAliveCountMax 30/' /etc/ssh/sshd_config
sed -i 's/^AllowTcpForwarding .*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitTunnel .*/PermitTunnel yes/' /etc/ssh/sshd_config

sed -i 's/^#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/keys\/ssh_host_rsa_key/' /etc/ssh/sshd_config
sed -i 's/^#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/keys\/ssh_host_dsa_key/' /etc/ssh/sshd_config
sed -i 's/^#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/keys\/ssh_host_ecdsa_key/' /etc/ssh/sshd_config
sed -i 's/^#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/keys\/ssh_host_ed25519_key/' /etc/ssh/sshd_config

sed -i 's/^#AuthorizedKeysCommandUser .*/AuthorizedKeysCommandUser nobody/' /etc/ssh/sshd_config
sed -i 's/^#AuthorizedKeysCommand .*/AuthorizedKeysCommand \/etc\/ssh\/gitauth_keys.sh %f/' /etc/ssh/sshd_config

# AuthorizedKeysCommand does not read environment variables, so we use them with `source`
if [[ -n ${GITAUTH_URL} ]]; then
cat > /etc/ssh/gitauth_keys.env  << EOF
GITAUTH_URL=${GITAUTH_URL}
GITAUTH_SCOPE=${GITAUTH_SCOPE}
GITAUTH_USERNAME=${GITAUTH_USERNAME}
GITAUTH_PASSWORD=${GITAUTH_PASSWORD}
OUTSIDE_COLLABORATORS=${OUTSIDE_COLLABORATORS}
EOF
fi

env > /etc/environment
# We add -D to make it non-interactive, but then the user is locked out.
adduser www-admin -D -G www-data -s /bin/bash -h /app
# So set an empty password after the user is created.
echo "www-admin:" | chpasswd

# Pass environment variables down to container, so SSH can pick it up and drush commands work too.
mkdir ~www-admin/.ssh/
env | grep -v HOME > ~www-admin/.ssh/environment

echo "umask 0002" >> ~www-admin/.profile

# Trigger lagoon entrypoint scripts if present.
if [ -f /lagoon/entrypoints.sh ] ; then /lagoon/entrypoints.sh ; fi

# Trigger silta entrypoint scripts if present.
if [ -f /silta/entrypoint.sh ] ; then /silta/entrypoint.sh ; fi

# run SSH server
exec /usr/sbin/sshd -D -E /proc/self/fd/2
