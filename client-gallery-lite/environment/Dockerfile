# The machine a factory builds client gallery lite on, and (as a fresh copy holding only /app)
# the machine its build is graded on. Playwright 1.63.0 on Ubuntu 24.04, with Node 24, npm 11,
# Python 3.12, git and curl. It also holds PostgreSQL 18 and SeaweedFS 4.45, at the versions of the
# runtime realm niflheim-local, for a product that wants them; the product starts them itself (the
# image starts no service and holds no cluster). Anything else a build needs, it installs while
# building; only what ends up in /app is carried to grading.

# SeaweedFS 4.45: niflheim-local's s3 service image, by its digest. Its weed binary is static.
FROM docker.io/chrislusf/seaweedfs:4.45@sha256:fc9f76fa993ad69966ffeb2f65d0318fcae39c6f8e20cf68ef7b3a5cb97769e5 AS weed

FROM mcr.microsoft.com/playwright:v1.63.0-noble@sha256:eff16c30e6f3f4af0a03fa4b706120d5e9b0891c344a27d64559aff5900a4a27

# PostgreSQL 18.4, the minor of niflheim-local's postgres image, from the PostgreSQL project's archive
# (apt-archive.postgresql.org keeps every version; the main repository only the newest). Its key is
# checked by fingerprint. postgresql-common goes first and is told to make no cluster, as the
# official postgres image does; the product makes its own.
ARG PG_VERSION=18.4-1.pgdg24.04+1
ARG PG_COMMON_VERSION=293.pgdg24.04+1
ARG PGDG_FINGERPRINT=B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /tmp/pgdg.asc; \
    test "$(gpg --show-keys --with-colons /tmp/pgdg.asc | awk -F: '$1 == "fpr" { print $10; exit }')" = "$PGDG_FINGERPRINT"; \
    gpg --dearmor -o /usr/share/keyrings/pgdg.gpg /tmp/pgdg.asc; \
    rm /tmp/pgdg.asc; \
    echo 'deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt-archive.postgresql.org/pub/repos/apt noble-pgdg-archive main' \
      > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "postgresql-common=$PG_COMMON_VERSION" "postgresql-client-common=$PG_COMMON_VERSION"; \
    sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf; \
    grep -qx 'create_main_cluster = false' /etc/postgresql-common/createcluster.conf; \
    apt-get install -y --no-install-recommends \
      "postgresql-18=$PG_VERSION" "postgresql-client-18=$PG_VERSION" "libpq5=$PG_VERSION"; \
    test ! -e /var/lib/postgresql/18/main; \
    rm -rf /var/lib/apt/lists/*
ENV PATH=/usr/lib/postgresql/18/bin:$PATH

COPY --from=weed /usr/bin/weed /usr/local/bin/weed

# Grading uses these; the product must not depend on them.
WORKDIR /grader
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund && npx playwright --version

# Grading starts the product as this unprivileged user, who owns /app.
RUN useradd --create-home --shell /bin/bash app && mkdir -p /app

WORKDIR /app
