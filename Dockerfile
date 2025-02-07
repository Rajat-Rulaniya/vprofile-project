FROM tomcat:9-jdk11
LABEL "Project"="Vprofile"
LABEL "Author"="Imran"

RUN rm -rf /var/lib/tomcat/webapps/*
COPY ./target/vprofile-v2.war /var/lib/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
WORKDIR /usr/local/tomcat/
VOLUME /usr/local/tomcat/webapps
