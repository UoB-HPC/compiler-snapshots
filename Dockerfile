FROM centos:7
RUN yum install -y centos-release-scl
RUN yum install -y \
    https://repo.ius.io/ius-release-el7.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y devtoolset-10 file bzip2 texinfo flex git236 jq ninja-build python3 cmake3 wget