# Silta Robot Framework Docker image

Docker image based on official instructions at https://docs.robotframework.org/docs/using_rf_in_ci_systems/docker.

## Usage

```bash
docker run --rm -v $(pwd)/robot-framework-tests/:/tests --ipc=host --user pwuser wunderio/silta-robot-framework bash -c "robot --outputdir /tmp/output /tests"
```

## Resources

Home page: https://robotframework.org/
Documentation: https://docs.robotframework.org/
