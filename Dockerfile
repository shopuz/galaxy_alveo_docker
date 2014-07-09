# Galaxy
#
# VERSION       0.1

FROM ubuntu:12.10

MAINTAINER Suren Shrestha, shopuz@gmail.com

# make sure the package repository is up to date
RUN apt-get update

# Set Apache User and Group
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# Install all requirements that are recommend by the Galaxy project
RUN apt-get install  -y autoconf
RUN apt-get install  -y automake
RUN apt-get install  -y build-essential
RUN apt-get install  -y gfortran
RUN apt-get install  -y cmake
RUN apt-get install  -y git-core
RUN apt-get install  -y libatlas-base-dev
RUN apt-get install  -y libblas-dev
RUN apt-get install  -y liblapack-dev
RUN apt-get install  -y mercurial
RUN apt-get install  -y subversion
RUN apt-get install  -y python-dev
RUN apt-get install  -y pkg-config
RUN apt-get install  -y openjdk-7-jre
RUN apt-get install  -y python-setuptools
RUN apt-get install  -y python-pip
RUN apt-get install  -y r-base
RUN apt-get install  -y wget


# Used to get Galaxy running in Docker with Apache2 and PostgreSQL
RUN apt-get install  -y postgresql
RUN apt-get install  -y apache2
RUN apt-get install  -y libapache2-mod-xsendfile
RUN apt-get install  -y sudo

# samtools is used to handle BAM files inside of Galaxy
RUN apt-get install  -y samtools

# Load required Apache Modules
RUN a2enmod xsendfile
RUN a2enmod proxy
RUN a2enmod proxy_balancer
RUN a2enmod proxy_http
RUN a2enmod rewrite

# Download and update Galaxy to the latest stable release
WORKDIR /mnt/galaxy
RUN hg clone -u 578b9185b556ce59c170d3fa0b422bd7773d0693 https://bitbucket.org/galaxy/galaxy-dist
RUN rm -rf galaxy-app
RUN mv galaxy-dist galaxy-app
#Add . /
WORKDIR /mnt/galaxy/galaxy-app
RUN sudo git init
RUN sudo git remote add origin git://github.com/IntersectAustralia/hcsvlab-galaxy.git
RUN sudo git fetch --all
RUN sudo git reset --hard origin/master
RUN sudo cp shed_tool_conf.xml.sample shed_tool_conf.xml
RUN sudo adduser galaxy

WORKDIR /mnt/galaxy
RUN sudo chown -R galaxy galaxy-app

# Setup R for ParseEval
CMD R CMD [install.packages],["lattice"],[repos="http://cran.ms.unimelb.edu.au/"]
CMD R CMD [install.packages],["latticeExtra"],[repos="http://cran.ms.unimelb.edu.au/"]
CMD R CMD [install.packages],["gridExtra"],[repos="http://cran.ms.unimelb.edu.au/"]

# Setup NLTK
RUN sudo pip install -U numpy
RUN sudo easy_install -U distribute
#RUN sudo pip install -U pyyaml nltk
#RUN sudo mkdir /usr/share/nltk_data
#RUN sudo python -m nltk.downloader -d /usr/share/nltk_data all

# Install the Johnson Charniak Parser
RUN sudo apt-get install flex -y
WORKDIR /mnt/galaxy
RUN sudo wget http://web.science.mq.edu.au/~mjohnson/code/reranking-parser-2011-12-17.tgz
RUN sudo tar -zxvf reranking-parser-2011-12-17.tgz
RUN sudo chown -R galaxy reranking-parser

ADD ./best-parses.cc /tmp/best-parses.cc
RUN sudo cp -f /tmp/best-parses.cc /mnt/galaxy/reranking-parser/second-stage/programs/features/best-parses.cc
WORKDIR /mnt/galaxy/reranking-parser
RUN sudo make

# Install the JC Parser NLTK wrapper
WORKDIR /mnt/galaxy
RUN sudo apt-get install python-tk -y
RUN sudo git clone git://github.com/IntersectAustralia/jcp-nltk-wrapper.git
#RUN sudo cp /mnt/galaxy/jcp-nltk-wrapper/parse/* /usr/local/lib/python2.7/dist-packages/nltk/parse

#ADD ./johnsoncharniak.ini /tmp/johnsoncharniak.ini
#ADD ./johnsoncharniak.py /tmp/johnsoncharniak.py
#RUN sudo cp -f /tmp/johnsoncharniak.ini /usr/local/lib/python2.7/dist-packages/nltk/parse/
#RUN sudo cp -f /tmp/johnsoncharniak.py /usr/local/lib/python2.7/dist-packages/nltk/parse/


#Set up for displaying parse trees
#RUN sudo apt-get install xvfb -y
#RUN export DISPLAY=:1
#RUN Xvfb :1 -screen 0 1024x768x24 &
#RUN sudo xhost +
#RUN sudo echo "export DISPLAY=:1" >> ~/.bashrc


# Configure Galaxy to use the Tool Shed
ADD ./universe_wsgi.ini /tmp/universe_wsgi.ini
RUN cp -f /tmp/universe_wsgi.ini /mnt/galaxy/galaxy-app/universe_wsgi.ini

#RUN mkdir ~/shed_tools
#RUN mkdir ~/galaxy-central/tool_deps

#RUN sed -i 's|#database_connection.*|database_connection = postgres://galaxy:galaxy@localhost:5432/galaxy|g' ~/galaxy-central/universe_wsgi.ini
#RUN sed -i 's|#tool_dependency_dir = None|tool_dependency_dir = ./tool_deps|g' ~/galaxy-central/universe_wsgi.ini
#RUN sed -i 's|#tool_config_file|tool_config_file|g' ~/galaxy-central/universe_wsgi.ini
#RUN sed -i 's|#tool_path|tool_path|g' ~/galaxy-central/universe_wsgi.ini
#RUN sed -i 's|#admin_users = None|admin_users = admin@galaxy.org|g' ~/galaxy-central/universe_wsgi.ini
#RUN sed -i 's|#master_api_key=changethis|master_api_key=HSNiugRFvgT574F43jZ7N9F3|g' ~/galaxy-central/universe_wsgi.ini
# Render SVG images properly
#RUN sed -i 's|#serve_xss_vulnerable_mimetypes.*|serve_xss_vulnerable_mimetypes = True|g' ~/galaxy-central/universe_wsgi.ini
#RUN sed -i 's|#brand = None|brand = Galaxy Docker Build|g' ~/galaxy-central/universe_wsgi.ini

# Fetching all Galaxy python dependencies
#RUN python scripts/fetch_eggs.py

# Define the default postgresql database path
# If you want to save your data locally you need to set GALAXY_DOCKER_MODE=HOST
#ENV PG_DATA_DIR_DEFAULT /var/lib/postgresql/9.1/main/

# Include all needed scripts from the host
#ADD ./setup_postgresql.py /galaxy-central/setup_postgresql.py
#ADD ./create_galaxy_user.py /galaxy-central/create_galaxy_user.py
ADD ./export_user_files.py /galaxy-central/export_user_files.py

#ADD ./ctb.apache.conf /tmp/ctb.apache.conf
ADD ./startup.sh /usr/bin/startup

RUN chmod +x /usr/bin/startup
#RUN cp /tmp/ctb.apache.conf /etc/apache2/sites-available/


#RUN a2ensite ctb.apache.conf
#RUN sudo /etc/init.d/apache2 restart
#RUN service postgresql stop

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'
#RUN service postgresql stop
#RUN rm $PG_DATA_DIR_DEFAULT -rf
#RUN python setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT
#RUN service postgresql start && sh create_db.sh
#RUN service postgresql start && sleep 5 && python create_galaxy_user.py --user admin@galaxy.org --password admin --key admin
#RUN service postgresql start && sh run.sh --daemon && sleep 120



# Mark one folders as imported from the host.
VOLUME ["/export/"]

# Expose port 80 to the host
EXPOSE :80

# Set up proxies for galaxy and toolshed
ADD ./galaxy_vhost.conf /tmp/galaxy_vhost.conf
RUN cp /tmp/galaxy_vhost.conf /etc/apache2/sites-available/galaxy_vhost.conf

RUN sudo /etc/init.d/apache2 restart


# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
RUN rm ./.hg/ -rf
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

