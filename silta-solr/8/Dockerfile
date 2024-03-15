FROM geerlingguy/solr:8.11.2

# Replacing log4j core and api for CVE-2021-45105, CVE-2021-44228 and CVE 2021-45046 mitigation
ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.13.3/log4j-api-2.13.3.jar /opt/solr/contrib/prometheus-exporter/lib/log4j-api-2.13.2.jar
ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.17.0/log4j-core-2.17.0.jar /opt/solr/contrib/prometheus-exporter/lib/log4j-core-2.13.2.jar
