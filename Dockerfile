# Handles OS Level Dependencies
# Importing an image with python 3.9, alpine is a lightweight linux library
FROM python:3.9-alpine3.13
# FROM docker.io/library/python:3.9-alpine3.13
# Tells others who is maintaining this app
LABEL maintainer="kinhouu"
# Allows python output to be printed immediately (unbuffered) to the console
ENV PYTHONUNBUFFERED 1

# Copyies requirements.txt file from local machine to  the docker image: /tmp/requirements.txt
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
# Copies our application files from local machine (./app) into docker image (/app)
COPY ./app /app
# Setting working directory, default directorywhere commands are going to be run from (dunnid to specify directory when running commands later)
WORKDIR /app
# Expose port 8000 from container to local machine, allow us to access port on container (connect to django dev server)
EXPOSE 8000

# Setting default Development mode to false
ARG DEV=false
# Runs a command on the alpine image, in a single command block
# Cannot run commnads individually, as it would create an image layer on each command ran (image will be heavyweight)
# Block 1: Creates new virtual env to store dependencies (prevents version conflicts with base image)
RUN python -m venv /py && \
    # Block 2: Upgrade python package manager in VE
    /py/bin/pip install --upgrade pip && \
    # Block 3: Installing package: Postgresql client (for psycopg2 to connect to postgres)
    apk add --update --no-cache postgresql-client && \
    # Block 4: Sets a virtual dependency (groups dependencies we installed into 'tmp-build-deps' for easier removal)
    apk add --update --no-cache --virtual .tmp-build-deps \
        # Specifies psycopg2 dependencies to be installed
        build-base postgresql-dev musl-dev && \
    # Block 5: Install requirements in requirements.txt
    /py/bin/pip install -r /tmp/requirements.txt && \
    # Shell code (bash script) - that installs requirements.dev.txt if in development mode 
    # /py/bin/pip install -r /tmp/requirements.dev.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    # Block 6: Remove tmp directory, get rid of extra dependencies once image is created (best practice to keep docker images lightweight)
    rm -rf /tmp && \
    # Block 7: Remove 'tmp-build-des' (installation dependencies)
    apk del .tmp-build-deps && \
    # Block 8: Add new user in image, best practice not to use root user (if app is compromised, attacker may have full access to container)
    adduser \
        # Prevent others from logging into container using password, only by default when running the app
        --disabled-password \
        # Don't create home directory for user, keep image lightweight
        --no-create-home \
        # Specify name of user
        django-user

# Updates environment variable in image (auto created on linux OS), defines all directories where executables can be run
# Add "/py/bin" to the path, so we don't have to specify "/py/bin" everytime we run python commands
ENV PATH="/py/bin:$PATH"

# Last line of docker file
# Specifies the user we are switching to (every command was ran as root user before this line)
USER django-user