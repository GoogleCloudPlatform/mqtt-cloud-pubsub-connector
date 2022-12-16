FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:412.0.0

# Install numpy as recommended by the IAP documentation
# See https://cloud.google.com/iap/docs/using-tcp-forwarding#increasing_the_tcp_upload_bandwidth
RUN "$(gcloud info --format="value(basic.python_location)")" \
    -m pip install numpy

VOLUME ["/root/.ssh"]
