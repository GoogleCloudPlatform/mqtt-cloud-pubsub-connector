FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:427.0.0

WORKDIR "/"
COPY container-images/gcloud-sdk/requirements.txt requirements.txt

RUN "$(gcloud info --format="value(basic.python_location)")" \
    -m pip install \
    --require-hashes \
    --requirement requirements.txt \
    && rm requirements.txt

VOLUME ["/root/.ssh"]
