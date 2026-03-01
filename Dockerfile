# LOHHLA Dockerfile
# Builds an image with LOHHLA and required dependencies.
# To include Novoalign (Novocraft) in the image, pass build-arg NOVO_URL with a direct download link.

FROM rocker/r-ver:4.3.2

ARG DEBIAN_FRONTEND=noninteractive
ARG NOVO_URL=""
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl ca-certificates gnupg2 dirmngr apt-transport-https \
    build-essential git default-jre libxml2-dev libssl-dev libcurl4-openssl-dev zlib1g-dev \
  samtools bedtools unzip bzip2 \
  libbz2-dev liblzma-dev libpcre3-dev libncurses5-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Picard (jar)
ENV PICARD_VERSION=2.27.4
RUN mkdir -p /opt/picard \
 && wget -q -O /opt/picard/picard.jar https://github.com/broadinstitute/picard/releases/download/${PICARD_VERSION}/picard.jar || true

# Create work dirs and copy LOHHLA source into the image
WORKDIR /opt/lohhla
COPY . /opt/lohhla

# If the repository includes a local `src/` (for example the Novocraft tarball
# or extracted binaries), copy it into the image at `/src` so tools are available
# without needing an external download.
COPY src /src
RUN if [ -d /src ]; then chmod -R a+rx /src || true; fi

# If a Novocraft tarball was placed in `src/`, extract it into /src and expose
# the `novoalign` binary on the PATH by symlinking it into /usr/local/bin.
RUN set -eux; \
    for f in /src/*.tar.gz; do \
      if [ -f "$f" ]; then echo "Extracting $f"; tar -xzf "$f" -C /src || true; fi; \
    done; \
    # find executable named novoalign and symlink into /usr/local/bin
    bin=$(find /src -type f -name novoalign -perm /111 -print -quit || true); \
    if [ -n "$bin" ]; then echo "Found novoalign at $bin -> symlinking"; ln -sf "$bin" /usr/local/bin/novoalign; chmod a+rx "$bin"; fi
# remove any novocraft tarball from /src so the tar.gz isn't baked into final image
RUN rm -f /src/*.tar.gz || true

# Prepare /src for external tools (novocraft/novoalign will be downloaded here if NOVO_URL is provided)
RUN mkdir -p /src \
 && if [ -n "$NOVO_URL" ]; then \
      echo "Downloading Novoalign from $NOVO_URL" && \
      wget -q -O /src/novoalign_linux.tar.gz "$NOVO_URL" && \
      tar -xzf /src/novoalign_linux.tar.gz -C /src || true; \
    else \
      echo "No NOVO_URL provided; skipping novocraft download. You can mount /src or provide NOVO_URL build-arg."; \
    fi

# If novoalign binary is present in /src make it executable and add /src to PATH
ENV PATH="/src:${PATH}"

# Install R packages required by LOHHLA (make installs more robust; install deps first)
RUN set -eux; \
  Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); install.packages(c("seqinr","beeswarm","zoo","optparse"), dependencies=TRUE)'; \
  Rscript -e 'if (!requireNamespace("BiocManager", quietly=TRUE)) install.packages("BiocManager", repos="https://cloud.r-project.org")'; \
  Rscript -e 'BiocManager::install(c("Biostrings","Rsamtools"), ask=FALSE)'

# Ensure any novoalign binary in /src is executable
RUN if ls /src/novo* 1> /dev/null 2>&1; then chmod -R a+rx /src || true; fi

RUN chmod -R a+rX /opt/lohhla

# Default entrypoint runs the LOHHLA R script. Users may override CMD/ENTRYPOINT as needed.
ENTRYPOINT ["Rscript", "/opt/lohhla/LOHHLAscript.R"]
