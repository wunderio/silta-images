#!/usr/bin/env sh

if [ ${SSMTP_REWRITEDOMAIN+x} ]; then
  echo -e "\nrewriteDomain=${SSMTP_REWRITEDOMAIN}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_AUTHUSER+x} ]; then
  echo -e "\nAuthUser=${SSMTP_AUTHUSER}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_AUTHPASS+x} ]; then
  echo -e "\nAuthPass=${SSMTP_AUTHPASS}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_USETLS+x} ]; then
  echo -e "\nUseTLS=${SSMTP_USETLS}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_USESTARTTLS+x} ]; then
  echo -e "\nUseSTARTTLS=${SSMTP_USESTARTTLS}" >> /etc/ssmtp/ssmtp.conf
fi

if [ ${SSMTP_MAILHUB+x} ]; then
  echo -e "\nmailhub=${SSMTP_MAILHUB}" >> /etc/ssmtp/ssmtp.conf
fi
