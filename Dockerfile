# Docker with rvm + gems (v: 2016022201)
FROM ruby:2.7.1-slim
MAINTAINER support@easysoftware.com

# L1: install default deps
RUN apt-get update; \
    apt-get -y --no-install-recommends install \
    tree \
    git \
    uuid-dev \
    imagemagick \
    libmagickcore-dev \
    libmagickwand-dev \
    libxapian-dev \
    zip \
    bzip2 \
    libxslt-dev \
    libxml2-dev \
    xz-utils \
    curl \
    rsync \
    wget \
    gcc \
    make \
    g++ \
    gettext-base \
    vim-tiny \
    xvfb \
    libfontenc1 \
    xfonts-75dpi \
    xfonts-base \
    xfonts-utils \
    xfonts-encodings \
    nodejs; apt-get clean

# Install wkhtmltopdf
RUN curl -kL pkg.easy2.cloud/debian/10/wkhtmltox_0.12.5-1.buster_amd64.deb -o /tmp/wkhtmltopdf-buster.deb ;\
    dpkg -i /tmp/wkhtmltopdf-buster.deb

# Allow pass Access Key to https://gems.easysoftware.com/help
ARG BUNDLE_GEMS__EASYSOFTWARE__COM
ENV BUNDLE_GEMS__EASYSOFTWARE__COM $BUNDLE_GEMS__EASYSOFTWARE__COM

# Build against prefered mysql database server (`mysql` or `maridadb` [default])
ARG DB
ENV DB $DB

ENV HOME "/opt/easy"
ENV RAILS_DIR="${HOME}/current" \
    RAILS_DATA="${HOME}/files" \
    RAILS_LOG="${HOME}/log" \
    RUBY_VERSION="${RUBY_VERSION}" \
    RAILS_ENV="production" \
    RAILS_MAX_WORKERS="1" \
    RAILS_MAX_THREADS="1"

RUN mkdir -p ${RAILS_DIR} ${RAILS_DATA} ${RAILS_LOG} 
VOLUME ["${RAILS_DATA}", "${RAILS_LOG}"]
COPY . ${RAILS_DIR}
RUN bundle config set without 'development test'
WORKDIR ${RAILS_DIR}

RUN /bin/bash -l -c "${RAILS_DIR}/bin/.docker-install.sh"

# Finally run bundle install
RUN bundle install --jobs $(nproc) --retry 5

EXPOSE 3000/tcp
ENTRYPOINT ["./docker-entrypoint.sh"]
