FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      zsh git gnupg openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /usr/bin/zsh tester
USER tester
WORKDIR /home/tester

RUN touch /home/tester/.zshrc && mkdir -p /home/tester/.ssh

COPY --chown=tester:tester lib/           /home/tester/plugin/lib/
COPY --chown=tester:tester tests/test.zsh /home/tester/test.zsh

CMD ["/usr/bin/zsh", "/home/tester/test.zsh"]
