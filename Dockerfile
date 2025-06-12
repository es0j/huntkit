FROM ubuntu

LABEL maintainer="Matt McNamee"

# Environment Variables
ENV HOME=/root
ENV TOOLS="/opt"
ENV ADDONS="/usr/share/addons"
ENV WORDLISTS="/usr/share/wordlists"
ENV GO111MODULE=on
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=${HOME}/:${GOPATH}/bin:${GOROOT}/bin:${PATH}
ENV DEBIAN_FRONTEND=noninteractive

# Create working dirs
WORKDIR /root
RUN mkdir $WORDLISTS && mkdir $ADDONS

# ------------------------------
# --- Common Dependencies ---
# ------------------------------

# Install Essentials
RUN apt update && \
  apt install -y --no-install-recommends --fix-missing \
  apt-utils \
  # awscli \
  build-essential \
  curl \
  dnsutils \
  git \
  iputils-ping \
  jq \
  libgmp-dev \
  libpcap-dev \
  net-tools \
  python3 \
  python3-pip \
  tzdata \
  wget \
  whois \
  zip \
  unzip \
  libgobject-2.0-0 \
  libasound2t64 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install tools & dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends --fix-missing \
  dirb \
  nmap \
  hydra \
  sqlmap \
  # wpscan
  libcurl4-openssl-dev \
  libxml2 \
  libxml2-dev \
  libxslt1-dev \
  ruby-dev \
  zlib1g-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install go
RUN cd /opt && \
  ARCH=$( arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/ ) && \
  wget https://dl.google.com/go/go1.21.1.linux-${ARCH}.tar.gz && \
  tar -xvf go1.21.1.linux-${ARCH}.tar.gz && \
  rm -rf /opt/go1.21.1.linux-${ARCH}.tar.gz && \
  mv go /usr/local

# Install Python common dependencies
#RUN python3 -m pip install --upgrade --break-system-packages paramiko

# ------------------------------
# --- Tools ---
# ------------------------------


# dalfox
RUN go install github.com/hahwul/dalfox/v2@latest

# fuff
RUN go install github.com/ffuf/ffuf@latest

# gau
RUN go install github.com/lc/gau/v2/cmd/gau@latest && \
  echo "alias gau='/go/bin/gau'" >> ~/.zshrc

# httpx
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# nuclei
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest && \
  git clone --depth 1 https://github.com/projectdiscovery/nuclei-templates.git $ADDONS/nuclei && \
  rm -rf $ADDONS/nuclei/.git

# subfinder
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest


#naabu
RUN go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

# unfurl
RUN go install -v github.com/tomnomnom/unfurl@latest

# wafw00f
RUN python3 -m pip install --break-system-packages wafw00f

# wpscan
RUN gem install wpscan

#gobuster
RUN go install github.com/OJ/gobuster/v3@latest

# wfuzz
# RUN pip install wfuzz

# whatweb
RUN git clone --depth 1 https://github.com/urbanadventurer/WhatWeb.git $TOOLS/whatweb && \
  cd $TOOLS/whatweb && \
  chmod a+x whatweb && \
  ln -sf $TOOLS/whatweb/whatweb /usr/local/bin/whatweb && \
  rm -rf .git

# eyeballer
RUN git clone --depth 1 https://github.com/BishopFox/eyeballer $TOOLS/eyeballer && \
  cd $TOOLS/eyeballer && \
  python3 -m pip install --break-system-packages -r requirements.txt || : && \
  chmod a+x eyeballer.py && \
  ln -sf $TOOLS/eyeballer/eyeballer.py /usr/local/bin/eyeballer && \
  wget https://github.com/BishopFox/eyeballer/releases/download/3.0/bishop-fox-pretrained-v3.h5 && \
  rm -rf .git

# dirsearch
RUN git clone https://github.com/maurosoria/dirsearch.git --depth 1 && \
  cd $TOOLS/dirsearch && \
  python3 -m pip install --break-system-packages -r requirements.txt || : && \
  python3 setup.py || : \
  rm -rf .git

# ------------------------------
# --- Wordlists ---
# ------------------------------

# seclists
#RUN  git clone --depth 1 https://github.com/danielmiessler/SecLists.git $WORDLISTS/seclists
COPY SecLists/Discovery $WORDLISTS/seclists/

# Symlink other wordlists
RUN ln -sf $( find /go/pkg/mod/github.com/\!o\!w\!a\!s\!p/\!amass -name wordlists ) $WORDLISTS/amass && \
  #ln -sf /usr/share/brutespray/wordlist $WORDLISTS/brutespray && \
  ln -sf /usr/share/dirb/wordlists $WORDLISTS/dirb && \
  #ln -sf /usr/share/setoolkit/src/fasttrack/wordlist.txt $WORDLISTS/fasttrack.txt && \
  #ln -sf /opt/metasploit-framework/embedded/framework/data/wordlists $WORDLISTS/metasploit && \
  ln -sf /usr/share/nmap/nselib/data/passwords.lst $WORDLISTS/nmap.lst 
  #ln -sf /etc/theHarvester/wordlists $WORDLISTS/theharvester

# ------------------------------
# --- Other utilities ---
# ------------------------------

# Copy the startup script across
COPY ./startup.sh /startup.sh

# ------------------------------
# --- Config ---
# ------------------------------

# Easier to access list of nmap scripts
RUN ln -s /usr/share/nmap/scripts/ $ADDONS/nmap

# ------------------------------
# --- Finished ---
# ------------------------------

# Start up commands
ENTRYPOINT ["bash", "/startup.sh"]
CMD ["/bin/bash"]
