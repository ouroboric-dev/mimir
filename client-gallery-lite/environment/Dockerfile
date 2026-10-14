# The machine a factory builds client gallery lite on, and (as a fresh copy holding only /app)
# the machine its build is graded on. Playwright 1.63.0 on Ubuntu 24.04, with Node 24, npm 11,
# Python 3.12, git and curl. Anything else a build needs, it installs while building; only what
# ends up in /app is carried to grading.
FROM mcr.microsoft.com/playwright:v1.63.0-noble@sha256:eff16c30e6f3f4af0a03fa4b706120d5e9b0891c344a27d64559aff5900a4a27

# Grading uses these; the product must not depend on them.
WORKDIR /grader
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund && npx playwright --version

# Grading starts the product as this unprivileged user, who owns /app.
RUN useradd --create-home --shell /bin/bash app && mkdir -p /app

WORKDIR /app
