FROM centos:7

RUN yum install epel-release && yum update
RUN yum install rpm-build make m4 gcc-c++ autoconf automake ncurses-devel redhat-rpm-config rpmdevtools tar rpmlint yum-utils
RUN yum groupinstall "Development tools"
