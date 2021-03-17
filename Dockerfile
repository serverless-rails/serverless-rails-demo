#
# Stage 1
#
FROM ruby:3.0.1-slim AS build

WORKDIR /sr

ARG AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY \
    RAILS_ENV \
    RAILS_GROUPS=assets
ENV RAILS_ENV=${RAILS_ENV}

RUN apt-get -q update \
  && apt-get -q install -y --no-install-recommends \
    apt-transport-https gnupg curl \
  && curl --silent --show-error \
    --location https://deb.nodesource.com/gpgkey/nodesource.gpg.key | \
      apt-key add - \
  && curl -sL https://deb.nodesource.com/setup_16.x | bash \
  && apt-get -q update \
  && apt-get -q install -y --no-install-recommends \
    build-essential libyaml-dev libssl-dev tzdata \
    git-core zlib1g-dev libpq-dev nodejs awscli \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g yarn \
  && gem install bundler \
  && bundle config set clean 'true' \
  && bundle config set path '/bundle' \
  && bundle config unset deployment \
  && bundle config unset frozen \
  && bundle config set without 'development test' \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY Gemfile Gemfile.lock ./
RUN bundle install --quiet -j "$(getconf _NPROCESSORS_ONLN)" --retry 3

COPY Rakefile config.ru ./
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY ./ /sr/

RUN DATABASE_URL=postgres://localhost/dummy SECRET_KEY_BASE=x bundle exec rake assets:precompile \
  && aws s3 cp /sr/public/assets s3://serverless-rails-demo-$RAILS_ENV-client-assets/assets/ --recursive --quiet \
  && aws s3 cp /sr/public/packs s3://serverless-rails-demo-$RAILS_ENV-client-assets/packs/ --recursive --quiet

# cleanup unneeded content
RUN rm -rf \
    env \
    app/assets/images \
    vendor/cache \
    node_modules client \
    package.json yarn.lock \
  && mkdir -p public/assets \
  && touch \
    public/assets/.manifest.json \
    public/assets/.sprockets-manifest.json


#
# Stage 2
#
FROM ruby:3.0.1-slim AS app

ARG RAILS_ENV \
    REVISION
ENV RAILS_ENV=${RAILS_ENV} \
    HOME=/sr \
    RAILS_LOG_TO_STDOUT=true \
    GIT_COMMIT=${REVISION}

RUN addgroup --gid 1000 --system app \
  && adduser \
    --system -u 1000 --ingroup app --gecos '' \
    --home $HOME --shell /bin/bash \
    app

RUN apt-get -q update \
  && apt-get -q install -y --no-install-recommends \
    openssl libncurses5-dev libssl-dev libreadline-dev \
    vim-tiny curl openssh-server \
    # libs/headers needed at runtime
    postgresql-client tzdata nodejs \
    # upload handling stuff
    imagemagick \
  # anycable
  && curl -Ls https://github.com/anycable/anycable-go/releases/download/v1.1.3/anycable-go-linux-amd64 \
    --output /bin/anycable-go \
  && chmod +x /bin/anycable-go \
  && mkdir -m 0777 -p /conf \
  && ssh-keygen -A \
  && chmod o+r /etc/ssh/ssh_host_*_key \
  && echo "export GEM_HOME=/usr/local/bundle" >> /etc/profile \
  && echo "export RAILS_ENV=$RAILS_ENV" >> /etc/profile \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && gem install bundler \
  && bundle config set path '/bundle' \
  && bundle config set without 'development test'

COPY deployment /conf

COPY --from=build --chown=app:app /bundle /bundle
COPY --from=build --chown=app:app /sr /sr

USER app:app
WORKDIR /sr

RUN mkdir -p .ssh \
  && cp /conf/ecs.pub .ssh/authorized_keys \
  && chmod og-rwx .ssh/authorized_keys \
  && echo "${REVISION}" > /sr/REVISION

COPY --chown=app:app config.ru ./
COPY --chown=app:app deployment/puma.rb ./config/

# bake in the bootsnap cache
RUN bundle exec bootsnap precompile --gemfile Gemfile

# default start command
CMD exec bundle exec foreman start -f /conf/Procfile.web
