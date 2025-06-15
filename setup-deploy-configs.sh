#!/bin/bash
set -e

echo "INFO: Creating .ebextensions/docker.config..."
mkdir -p .ebextensions
cat > .ebextensions/docker.config <<EOT
commands:
  01-update-packages:
    command: "dnf update -y"

  02-install-docker:
    command: "dnf install -y docker"

  03-install-docker-compose:
    command: "dnf install -y docker-compose"

  04-check-docker:
    command: "docker --version && echo '✅ Docker installed successfully.'"

  05-check-docker-compose:
    command: "docker-compose --version && echo '✅ Docker Compose installed successfully.'"

  06-enable-docker:
    command: "systemctl enable docker && systemctl start docker"

  07-install-node:
    command: |
      dnf install -y gcc-c++ make curl
      curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
      dnf install -y nodejs

  08-check-node:
    command: "node -v && npm -v && echo '✅ Node.js 20 installed successfully.'"
EOT

echo "INFO: Creating .platform/hooks/prebuild.sh..."
mkdir -p .platform/hooks
cat > .platform/hooks/prebuild.sh <<EOT
#!/bin/bash
set -e
cd /var/app/current

echo "INFO: Starting Docker containers..."
docker-compose up -d

# Wait a bit for containers to initialize
sleep 5

# Check if a specific container (e.g., database) is running
DB_CONTAINER=\$(docker-compose ps | grep "db" | awk '{print \$1}')

if [[ "\$DB_CONTAINER" ]]; then
  echo "✅ The Database Container Is Up And Running"
else
  echo "❌ Database container failed to start!" >&2
  exit 1
fi
EOT

chmod +x .platform/hooks/prebuild.sh

echo "INFO: Configuration files created successfully."
