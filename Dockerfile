FROM debian:stretch


ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

USER root

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
# ERROR: no download agent available; install curl, wget, or fetch
		curl \
	; \
	rm -rf /var/lib/apt/lists/*

	ADD fix-permissions /usr/local/bin/fix-permissions
	# Create jovyan user with UID=1000 and in the 'users' group
	# and make sure these dirs are writable by the `users` group.
	RUN groupadd wheel -g 11 && \
	    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
	    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
	    useradd -m -s /bin/bash -N -g sudo "marcvs" && \
	    # adduser marcvs sudo && \
	    printf "tcho\ntcho" |passwd marcvs
	    # mkdir -p $CONDA_DIR && \
	    # chown $NB_USER:$NB_GID $CONDA_DIR && \
	    # chmod g+w /etc/passwd && \
	    # fix-permissions $HOME && \
	    # fix-permissions $CONDA_DIR


ENV JULIA_PATH /usr/local/julia
ENV PATH $JULIA_PATH/bin:$PATH

# https://julialang.org/juliareleases.asc
# Julia (Binary signing key) <buildbot@julialang.org>
# ENV JULIA_GPG 3673DF529D9049477F76B37566E3C7DC03D6E495

# https://julialang.org/downloads/
# ENV JULIA_VERSION 1.0.3

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi; \
# 	\
# # https://julialang.org/downloads/#julia-command-line-version
# # https://julialang-s3.julialang.org/bin/checksums/julia-1.0.3.sha256
# # this "case" statement is generated via "update.sh"
# 	dpkgArch="$(dpkg --print-architecture)"; \
# 	case "${dpkgArch##*-}" in \
# # amd64
# 		amd64) tarArch='x86_64'; dirArch='x64'; sha256='362ba867d2df5d4a64f824e103f19cffc3b61cf9d5a9066c657f1c5b73c87117' ;; \
# # arm32v7
# 		armhf) tarArch='armv7l'; dirArch='armv7l'; sha256='87c489ed92b1a17b231988ce59d64151b1e68700e6d503ded6085829d5587bc6' ;; \
# # arm64v8
# 		arm64) tarArch='aarch64'; dirArch='aarch64'; sha256='75f43df36d71cb2bf3106b9e16670cc152e2a31f8ea6d761a6fe1d630ead05c3' ;; \
# # i386
# 		i386) tarArch='i686'; dirArch='x86'; sha256='6c8cc02d63a602870f78e66d0fdeb7e26e75b3eba558a133a86420e1273bbdc1' ;; \
# 		*) echo >&2 "error: current architecture ($dpkgArch) does not have a corresponding Julia binary release"; exit 1 ;; \
# 	esac; \
	\
	# folder="$(echo "$JULIA_VERSION" | cut -d. -f1-2)"; \
	# curl -fL -o julia.tar.gz.asc "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${folder}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz.asc"; \
	# curl -fL -o julia.tar.gz     "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${folder}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz"; \
	curl -fL -o julia.tar.gz     "https://julialangnightlies-s3.julialang.org/bin/linux/x64/julia-latest-linux64.tar.gz"; \
	# echo "${sha256} *julia.tar.gz" | sha256sum -c -; \
	\
	# export GNUPGHOME="$(mktemp -d)"; \
	# gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$JULIA_GPG"; \
	# gpg --batch --verify julia.tar.gz.asc julia.tar.gz; \
	# command -v gpgconf > /dev/null && gpgconf --kill all; \
	# rm -rf "$GNUPGHOME" julia.tar.gz.asc; \
	\
	mkdir "$JULIA_PATH"; \
	tar -xzf julia.tar.gz -C "$JULIA_PATH" --strip-components 1; \
	rm julia.tar.gz; \
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
# smoke test
	julia --version

# USER $NB_UID

CMD ["julia"]
