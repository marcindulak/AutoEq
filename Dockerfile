FROM ubuntu:22.04
RUN apt update
RUN apt install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt update
RUN apt install -y nodejs
RUN apt -y install nodejs libsndfile1 python3 python3-dev python3-pip python3-venv

# Set the UID/GID of the user:group to the IDs of the user using this Dockerfile
ARG USER=nonroot
ARG GROUP=nonroot
ARG UID=1000
ARG GID=1000
RUN echo user:group ${USER}:${GROUP}
RUN echo uid:gid ${UID}:${GID}
RUN getent group ${GROUP} || groupadd --non-unique --gid ${GID} ${GROUP}
RUN getent passwd ${USER} || useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/false ${USER}
RUN if [ "${GID}" != "1000" ] || [ "${UID}" != "1000" ]; then \
	groupmod --non-unique --gid ${GID} ${GROUP} && \
	usermod --uid ${UID} --gid ${GID} ${USER} && \
	chown -R ${UID}:${GID} /home/${USER}; \
    fi

# Configure sudo
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    sudo && \
    rm -rf /var/lib/apt/lists/*
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}
RUN sudo -lU ${USER}
USER ${USER}
RUN sudo ls /etc
USER root

WORKDIR /app
RUN chown ${USER}:${GROUP} /app
USER ${USER}
COPY --chown=${USER}:${GROUP} ./autoeq/*.py ./autoeq/
COPY --chown=${USER}:${GROUP} ./webapp/ui/package.json ./webapp/ui/package.json
COPY --chown=${USER}:${GROUP} ./webapp/ui/package-lock.json ./webapp/ui/package-lock.json
COPY --chown=${USER}:${GROUP} ./webapp/ui/public ./webapp/ui/public
COPY --chown=${USER}:${GROUP} ./webapp/ui/src ./webapp/ui/src
COPY --chown=${USER}:${GROUP} ./webapp/ui/config ./webapp/ui/config
COPY --chown=${USER}:${GROUP} ./webapp/ui/scripts ./webapp/ui/scripts
COPY --chown=${USER}:${GROUP} ./webapp/main.py ./webapp/main.py
COPY --chown=${USER}:${GROUP} ./webapp/requirements.txt ./webapp/requirements.txt
COPY --chown=${USER}:${GROUP} ./pyproject.toml ./pyproject.toml
COPY --chown=${USER}:${GROUP} ./README.md ./README.md
USER ${USER}
RUN cd /home/${USER} && python3 -m venv venv && . venv/bin/activate
RUN echo "if [ -f ~/venv/bin/activate  ]; then . ~/venv/bin/activate; fi" >> /home/${USER}/.bashrc
RUN . /home/${USER}/venv/bin/activate && python3 -m pip install -U pip
RUN . /home/${USER}/venv/bin/activate && python3 -m pip install -U .
WORKDIR /app/webapp
RUN chown ${USER}:${GROUP} /app
RUN . /home/${USER}/venv/bin/activate && python3 -m pip install -U -r ./requirements.txt
WORKDIR /app/webapp/ui
RUN chown ${USER}:${GROUP} /app
RUN npm ci
RUN npm run build
WORKDIR /app/webapp
ENV APP_ENV=production
CMD . ~/venv/bin/activate && python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
