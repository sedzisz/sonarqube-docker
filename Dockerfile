
#
# SonarQube and PostgreSQL 9.4 with the PLV8 (Javascript) extensions
# http://172.16.1.34:9000/ default login is admin/admin
#

FROM phusion/baseimage:0.9.13
MAINTAINER cmbaughman@outlook.com

# These are all here for Phusion's Baseimage
ENV_HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]


# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent PostgreSQL 9.4 Beta.
RUN sh -c "echo deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main 9.4 > /etc/apt/sources.list.d/pgdg.list"
# Add sonar's Sourceforge repo
RUN sh -c "echo deb http://downloads.sourceforge.net/project/sonar-pkg/deb binary/ > /etc/apt/sources.list.d/sonar-pkg.list"

# Update the Ubuntu, Sourceforge, and PostgreSQL repository indexes
RUN apt-get update

# Install ''python-software-properties'', ''software-properties-common'' and PostgreSQL 9.4
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install python-software-properties software-properties-common wget curl unzip
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install postgresql-9.4 postgresql-client-9.4 postgresql-contrib-9.4

# Install SonarQube
# Note: Installs to /opt/sonar
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q --force-yes install sonar

# Run the rest of the commands as the ''postgres'' user created by the ''postgres-9.4'' package when it was ''apt-get installed''
USER postgres

# Create a PostgreSQL role named ''docker'' with ''docker'' as the password and
# then create a database `docker` owned by the ''docker'' role.
# Note: here we use ''&&\'' to run commands one after the other - the ''\''
#       allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf

# And add listen_addresses to postgresql.conf''
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Expose the SonarQube port
EXPOSE 9000

# Clean up stuff for phusion/baseimage:
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/usr/share/sonar"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.4/bin/postgres", "-D", "/var/lib/postgresql/9.4/main", "-c", "config_file=/etc/postgresql/9.4/main/postgresql.conf"]
