FROM centos:6

RUN yum -y install epel-release && yum -y update
RUN yum -y install rpm-build make m4 gcc-c++ autoconf automake ncurses-devel redhat-rpm-config rpmdevtools tar rpmlint yum-utils
RUN yum -y groupinstall "Development tools"
RUN cd && rpmdev-setuptree
