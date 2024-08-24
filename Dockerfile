FROM --platform=linux/amd64 perl:slim AS builder
# Install and build TeXLive
WORKDIR /latex
RUN mkdir build

RUN apt-get update && apt-get install wget -y

RUN wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz --quiet
RUN tar -xf install-tl-unx.tar.gz
RUN mv install-tl-*/* ./build

WORKDIR /latex/build
RUN perl ./install-tl --no-interaction --scheme=scheme-small --portable
ENV PATH="$PATH:/usr/local/texlive/bin/x86_64-linux"
RUN tlmgr update --self
RUN tlmgr install collection-fontsrecommended bbm bbm-macros siunitx

FROM --platform=linux/amd64 python:3.10-slim

# Copy in built texlive binaries and install convert (from imagemagick)
COPY --from=builder /usr/local/texlive /usr/local/texlive
ENV PATH="$PATH:/usr/local/texlive/bin/x86_64-linux/"
RUN apt-get update && apt-get install imagemagick -y

# Configure environemnt
WORKDIR /rtex
EXPOSE 5000/tcp
COPY conf/imagemagick.xml /etc/ImageMagick-6/policy.xml
COPY conf/texmf.cnf /usr/local/texlive/texmf.conf

# Install proejct dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the server in and run it
COPY . .
ENTRYPOINT ["python"]
CMD ["src/server.py"]
