#!/usr/bin/env bash
set -ex

docker build --pull --squash -t ghcr.io/katamaran-project/rocq:base rocq-base
docker image push ghcr.io/katamaran-project/rocq:base

for conf in $(jq -c '.[]' rocq-versions.json); do
	rocqversion=$(echo "${conf}" | jq -r '.rocq')
	irisversions=$(echo "${conf}" | jq -c '.iris')
	equationsversions=$(echo "${conf}" | jq -c '.equations')
	rocqtag="${rocqversion}"

	docker build --squash -t "ghcr.io/katamaran-project/rocq:$rocqtag" - <<- EOF
		FROM ghcr.io/katamaran-project/rocq:base
		RUN set -x \\
		&& opam pin add -vyj\$(nproc) rocq-core "${rocqversion}" \\
		&& opam clean -acrs --logs \\
		&& opam config list && opam list
	EOF
	docker image push "ghcr.io/katamaran-project/rocq:$rocqtag"

	for irisversion in $(echo "${irisversions}" | jq -cr '.[]'); do
		iristag="${rocqtag}_iris-${irisversion}"

		docker build --squash -t "ghcr.io/katamaran-project/rocq:$iristag" - <<- EOF
			FROM ghcr.io/katamaran-project/rocq:$rocqtag
			RUN set -x \\
			&& opam install -vyj\$(nproc) --ignore-constraints-on rocq-core rocq-iris=${irisversion} \\
			&& opam clean -acrs --logs \\
			&& opam config list && opam list
		EOF
		docker image push "ghcr.io/katamaran-project/rocq:$iristag"

		for equationsversion in $(echo "${equationsversions}" | jq -cr '.[]'); do
			equationstag="$(echo "${equationsversion}" | sed 's/+.*$//')"
			equationstag="${rocqtag}_iris-${irisversion}_equations-${equationstag}"

			docker build --squash -t "ghcr.io/katamaran-project/rocq:$equationstag" - <<- EOF
				FROM ghcr.io/katamaran-project/rocq:$iristag
				RUN set -x \\
				&& opam install -vyj\$(nproc) rocq-equations=${equationsversion} \\
				&& opam clean -acrs --logs \\
				&& opam config list && opam list
			EOF
			docker image push "ghcr.io/katamaran-project/rocq:$equationstag"
		done
	done
done
