FROM debian:trixie-slim
LABEL maintainer="steven.keuchel@gmail.com"

# Install system packages
RUN apt-get update -yq \
&& DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
   autoconf automake ca-certificates git hyperfine libgmp-dev m4 ocaml-nox opam pkg-config python3 rsync sudo time zlib1g-dev \
&& apt-get clean \
&& rm -fr /var/lib/apt/lists/*

# Add rocq user and drop root
RUN useradd -lmU -s /bin/bash -G sudo -p '' rocq
WORKDIR /home/rocq
USER rocq

# Install common packages
RUN set -x \
&& opam init -j$(nproc) --compiler ocaml-system --auto-setup --yes --disable-completion --disable-sandboxing \
&& opam repo add --all-switches --set-default rocq-released https://rocq-prover.org/opam/released \
&& opam install -vyj$(nproc) dune num ocamlfind zarith conf-findutils conf-gmp opam-depext \
&& opam clean -acrs --logs \
&& opam config list && opam list

ENTRYPOINT ["opam", "exec", "--"]
CMD ["/bin/bash", "--login"]
