FROM tomcat:9-jdk11
LABEL "Project"="Vprofile"
LABEL "Author"="Rajat"

WORKDIR /usr/local/tomcat/

RUN rm -rf webapps/*
COPY ./target/vprofile-v2.war webapps/ROOT.war

EXPOSE 8080
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
VOLUME ["/usr/local/tomcat/webapps"]
