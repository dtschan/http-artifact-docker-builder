FROM registry.access.redhat.com/openshift3/ose-docker-builder:v3.0.2.0
MAINTAINER Daniel Tschan <tschan@puzzle.ch>

ENV http_proxy=http://outappl.pnet.ch:3128/ https_proxy=http://outappl.pnet.ch:3128/ no_proxy=127.0.0.1,localhost,172.27.40.68,.pnet.ch,172.28.39.140

RUN env

RUN yum -y --disablerepo=* --enablerepo=rhel-7-server-rpms --enablerepo=rhel-7-server-extras-rpms --enablerepo=rhel-7-server-optional-rpms install docker; yum clean all

ADD ./build.sh /tmp/build.sh

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/tmp/build.sh"]
