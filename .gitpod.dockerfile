FROM gitpod/workspace-base

RUN echo "CI custom build from base 221130"

### NodeJS ###
USER gitpod
ENV NODE_VERSION=16.13.0
ENV TRIGGER_REBUILD=1
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | PROFILE=/dev/null bash \
    && bash -c ". .nvm/nvm.sh \
        && nvm install $NODE_VERSION \
        && nvm alias default $NODE_VERSION \
        && npm install -g typescript yarn node-gyp" \
    && echo ". ~/.nvm/nvm.sh"  >> /home/gitpod/.bashrc.d/50-node
ENV PATH=$PATH:/home/gitpod/.nvm/versions/node/v${NODE_VERSION}/bin

### Python ###
USER gitpod
RUN sudo install-packages python3-pip

ENV PATH=$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH
RUN curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && { echo; \
        echo 'eval "$(pyenv init -)"'; \
        echo 'eval "$(pyenv virtualenv-init -)"'; } >> /home/gitpod/.bashrc.d/60-python \
    && pyenv update \
    && pyenv install 3.10.8 \
    && pyenv global 3.10.8 \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --upgrade \
        setuptools wheel virtualenv pipenv pylint rope flake8 \
        mypy autopep8 pep8 pylama pydocstyle bandit notebook \
        twine \
    && sudo rm -rf /tmp/*USER gitpod
ENV PYTHONUSERBASE=/workspace/.pip-modules \
    PIP_USER=yes
ENV PATH=$PYTHONUSERBASE/bin:$PATH

# Setup PostgreSQL

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list' && \
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
    sudo apt-get update -y && \
    sudo apt-get install -y postgresql-14

ENV PGDATA="/workspace/.pgsql/data"

RUN mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/sockets \
    && echo '#!/bin/bash\n[ ! -d $PGDATA ] && mkdir -p $PGDATA && initdb --auth=trust -D $PGDATA\ncp $GITPOD_REPO_ROOT/.vscode/pg_hba.conf /workspace/.pgsql/data/\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" start\n' > ~/.pg_ctl/bin/pg_start \
    && echo '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" stop\n' > ~/.pg_ctl/bin/pg_stop \
    && chmod +x ~/.pg_ctl/bin/*

ENV PGDATABASE="postgres"

ENV PATH="/usr/lib/postgresql/14/bin:/home/gitpod/.nvm/versions/node/v${NODE_VERSION}/bin:$HOME/.pg_ctl/bin:$PATH"

# Add aliases

RUN echo 'alias run="python3 $GITPOD_REPO_ROOT/manage.py runserver 0.0.0.0:8000"' >> ~/.bashrc && \
    echo 'alias python=python3' >> ~/.bashrc && \
    echo 'alias pip=pip3' >> ~/.bashrc && \
    echo 'alias arctictern="python3 $GITPOD_REPO_ROOT/.vscode/arctictern.py"' >> ~/.bashrc && \
    echo 'alias font_fix="python3 $GITPOD_REPO_ROOT/.vscode/font_fix.py"' >> ~/.bashrc && \
    echo 'alias set_pg="export PGHOSTADDR=127.0.0.1"' >> ~/.bashrc && \
    echo 'alias unset_pg="unset PGHOSTADDR"' >> ~/.bashrc && \
    echo 'alias make_url="python3 $GITPOD_REPO_ROOT/.vscode/make_url.py "' >> ~/.bashrc && \
    echo 'FILE="$GITPOD_REPO_ROOT/.vscode/post_upgrade.sh"' >> ~/.bashrc && \
    echo 'if [ -z "$POST_UPGRADE_RUN" ]; then' >> ~/.bashrc && \
    echo '  if [[ -f "$FILE" ]]; then' >> ~/.bashrc && \
    echo '    . "$GITPOD_REPO_ROOT/.vscode/post_upgrade.sh"' >> ~/.bashrc && \
    echo "  fi" >> ~/.bashrc && \
    echo "fi" >> ~/.bashrc

ENV PORT="8080"
ENV IP="0.0.0.0"

# Despite the scary name, this is just to allow React and DRF to run together on Gitpod
ENV DANGEROUSLY_DISABLE_HOST_CHECK=true
