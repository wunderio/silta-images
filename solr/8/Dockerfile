FROM geerlingguy/solr:8.9.0

# Removing log4j core for CVE-2021-44228 and CVE 2021-45046 mitigation
RUN apt update && apt install zip -y && apt clean
RUN zip -q -d /opt/solr/contrib/prometheus-exporter/lib/log4j-core-*.jar org/apache/logging/log4j/core/lookup/JndiLookup.class || true
