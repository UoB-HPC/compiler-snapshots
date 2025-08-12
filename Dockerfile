FROM almalinux:8
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN yum config-manager --set-enabled powertools
RUN yum install -y gcc-toolset-14 file bzip2 texinfo flex git jq ninja-build python3 cmake3 wget