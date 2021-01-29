# Modified Mailhog

Docker container based on official varnish mailhog image, with extra moditications.

## Log suppression

Our deployments receive a steady flow of mailhog logs that are normally irrelevant (because it just works). We use [mailhog chart by codecentric](https://github.com/codecentric/helm-charts/tree/master/charts/mailhog) to deploy mailhog, but [there's no way to suppress logs](https://github.com/codecentric/helm-charts/pull/272) other than overriding entrypoint currently.  Our solution to this is to replace entrypoint in the Docker image and overriding the image source in chart.

## Resources

 - https://github.com/mailhog/MailHog
 - https://github.com/codecentric/helm-charts/tree/master/charts/mailhog
 - https://github.com/codecentric/helm-charts/pull/272