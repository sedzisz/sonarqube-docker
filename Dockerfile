
#
# SonarQube and PostgreSQL 9.4 with the PLV8 (Javascript) extensions
# http://172.16.1.34:9000/ default login is admin/admin
#

FROM ubuntu
MAINTAINER cbaughman@mandiant.com

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ''9.4''.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN echo "deb http://downloads.sourceforge.net/project/sonar-pkg/deb binary/" > /etc/apt/sources.list.d/sonar-pkg.list
# Update the Ubuntu and PostgreSQL repository indexes
RUN apt-get update

# Install ''python-software-properties'', ''software-properties-common'' and PostgreSQL 9.4
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get -y -q install python-software-properties software-properties-common
RUN apt-get -y -q install postgresql-9.4 postgresql-client-9.4 postgresql-contrib-9.4

# Install SonarQube
# Note: Installs to /opt/sonar
RUN apt-get -y -q install sonar

# Note: The official Debian and Ubuntu images automatically ''apt-get clean''
# after each ''apt-get''

RUN wget http://api.pgxn.org/dist/plv8/1.4.2/plv8-1.4.2.zip
RUN unzip plv8-1.4.2.zip
RUN cd plv8-1.4.2
RUN make && sudo make install
RUN cd -

# Run the rest of the commands as the ''postgres'' user created by the ''postgres-9.4'' package when it was ''apt-get installed''
USER postgres

# Create a PostgreSQL role named ''docker'' with ''docker'' as the password and
# then create a database `docker` owned by the ''docker'' role.
# Note: here we use ''&&\'' to run commands one after the other - the ''\''
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf

# And add ''listen_addresses'' to ''/etc/postgresql/9.4/main/postgresql.conf''
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Expose the SonarQube port
EXPOSE 9000

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.4/bin/postgres", "-D", "/var/lib/postgresql/9.4/main", "-c", "config_file=/etc/postgresql/9.4/main/postgresql.conf"]

RUN psql --command="create extension plv8;"

