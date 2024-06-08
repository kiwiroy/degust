# Build part 1
FROM ruby:2.4.6-stretch AS degust-builder

RUN echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list
RUN echo "deb-src [trusted=yes] http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list
RUN echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list
RUN echo "deb [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list
RUN echo "deb-src [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list

# Install node and R - See http://cloud.r-project.org/bin/linux/debian/
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && echo 'deb http://cloud.r-project.org/bin/linux/debian stretch-cran35/' > '/etc/apt/sources.list.d/r-base.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' \
    && apt-get update \
    && apt-get install -y nodejs r-base \
    && rm -rf /var/lib/apt/lists/*

# Install R libs - locfit is a dep of edgeR and later versions req 4.1
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/locfit/locfit_1.5-9.4.tar.gz', repos = NULL, type = 'source')"
RUN Rscript -e "install.packages(c('BiocManager','jsonlite')); BiocManager::install(version='3.9', ask=F); BiocManager::install(c('limma','edgeR','topconfects', 'RUVSeq'))"


ENV RAILS_ENV=production

# Grab Gemfile first so we can cache the docker layer from gems
WORKDIR /opt/degust-build
COPY Gemfile Gemfile.lock /opt/degust-build/
RUN gem update --system 3.2.3 \
    && gem install bundler -v 2.3.27 \
    && bundle install

# Grab the rest of degust for building
COPY . /opt/degust-build

# Build the js front-end
RUN rake degust:deps \
    && rake degust:build \
    && rake assets:precompile

# Copy files into place for the final-image
RUN ./scripts/production-files-copy.sh /opt/degust

###############################################
# Build part 2
FROM ruby:2.4.6-stretch

RUN echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list
RUN echo "deb-src [trusted=yes] http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list
RUN echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list
RUN echo "deb [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list
RUN echo "deb-src [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list

# Install node and R
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && echo 'deb http://cloud.r-project.org/bin/linux/debian stretch-cran35/' > '/etc/apt/sources.list.d/r-base.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' \
    && apt-get update \
    && apt-get install -y nodejs r-base \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/degust

# Copy the built R libraries
COPY --from=0 /usr/local/lib/R/site-library /usr/local/lib/R/site-library/

# Copy ruby bundler libraries
COPY --from=0 /usr/local/bundle /usr/local/bundle/

# Copy just the staged degust files
COPY --from=0 /opt/degust .

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=1

ARG run_user=root
ARG run_group=root

USER ${run_user}:${run_group}

# Run server (this will also migrate the db if necessary)
CMD ["/opt/degust/scripts/migrate-run.sh"]
