# syntax=docker/dockerfile:1.6

# --- Stage 1: Build ptouch-print from source -----------------------------------
# Override PTOUCH_PRINT_GIT / PTOUCH_PRINT_REF at build time to point at any fork.
FROM debian:bookworm-slim AS ptouch-build

ARG PTOUCH_PRINT_GIT=https://github.com/danhoban/ptouch-print.git
ARG PTOUCH_PRINT_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        git cmake build-essential pkg-config gettext \
        libusb-1.0-0-dev libgd-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 --branch "${PTOUCH_PRINT_REF}" "${PTOUCH_PRINT_GIT}" /opt/ptouch-print \
    && cmake -S /opt/ptouch-print -B /opt/ptouch-print/build \
    && cmake --build /opt/ptouch-print/build --parallel


# --- Stage 2: Runtime ----------------------------------------------------------
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

RUN echo "deb http://deb.debian.org/debian bookworm contrib" > /etc/apt/sources.list.d/contrib.list \
    && echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections \
    && apt-get update && apt-get install -y --no-install-recommends \
        libusb-1.0-0 libgd3 \
        fontconfig \
        fonts-dejavu fonts-liberation ttf-mscorefonts-installer \
        libcairo2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ptouch-build /opt/ptouch-print/build/ptouch-print /opt/ptouch-print/build/ptouch-print

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "labelmaker.py"]
