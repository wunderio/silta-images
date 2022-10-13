## Lighthouse
Lighthouse is a website performance test tool that can be used to measure website performance and find out slow queries and general improvement places.

How to run:

```yaml
### CIRCLECI/config.yml ###
jobs:

  lighthouse:
    docker:
      - image: #Silta Lighthouse image
    steps:
      - checkout

      - run: 
          name: Make output directory
          command: mkdir output

      - run: 
          name: Run the lighthouse tests
          command: lighthouse --chrome-flags="--headless --disable-gpu --no-sandbox" wunder.io --output-path=output/lighthouse-results.html

      - store_artifacts:
          path: output
```
`