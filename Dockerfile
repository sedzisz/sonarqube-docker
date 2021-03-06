#########################################################################
# SonarQube and PostgreSQL 9.6 with the PLV8 (Javascript) extensions
# http://172.16.1.34:9000/ default login is admin/admin
#########################################################################

FROM ubuntu:16.04
MAINTAINER zdzislaw.sedek@gmail.com

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN apt-get update
RUN apt-get -q -y install -f apt-transport-https

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ''9.6''.
RUN sh -c "echo deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main 9.6 > /etc/apt/sources.list.d/pgdg.list"
RUN sh -c "echo deb http://downloads.sourceforge.net/project/sonar-pkg/deb binary/ > /etc/apt/sources.list.d/sonar-pkg.list"
# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update

# Install ''python-software-properties'', ''software-properties-common'' and PostgreSQL 9.6
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install python-software-properties software-properties-common wget curl unzip
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6

# Install SonarQube
# Note: Installs to /opt/sonar
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install --allow-unauthenticated sonar

# Run the rest of the commands as the ''postgres'' user created by the ''postgres-9.6'' package when it was ''apt-get installed''
USER postgres

# Create a PostgreSQL role named ''docker'' with ''docker'' as the password and
# then create a database `docker` owned by the ''docker'' role.
# Note: here we use ''&&\'' to run commands one after the other - the ''\''
#       allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf

# And add ''listen_addresses'' to ''/etc/postgresql/9.6/main/postgresql.conf''
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf

# Expose the PostgreSQL port
#EXPOSE 5432

# Expose the SonarQube port
EXPOSE 9000

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/usr/share/sonar"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.6/bin/postgres", "-D", "/var/lib/postgresql/9.6/main", "-c", "config_file=/etc/postgresql/9.6/main/postgresql.conf"]
