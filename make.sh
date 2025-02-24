#!/usr/bin/env bash
set -ex

docker build --pull --squash -t ghcr.io/katamaran-project/coq:base base
docker image push ghcr.io/katamaran-project/coq:base

for conf in $(jq -c '.[]' versions.json); do
	coqversion=$(echo "${conf}" | jq -r '.coq')
	irisversions=$(echo "${conf}" | jq -c '.iris')
	equationsversions=$(echo "${conf}" | jq -c '.equations')
	coqtag="${coqversion}"

	docker build --squash -t "ghcr.io/katamaran-project/coq:$coqtag" - <<- EOF
		FROM ghcr.io/katamaran-project/coq:base
		RUN set -x \\
		&& opam pin add -vyj\$(nproc) coq "${coqversion}" \\
		&& opam clean -acrs --logs \\
		&& opam config list && opam list
	EOF
	docker image push "ghcr.io/katamaran-project/coq:$coqtag"

	for irisversion in $(echo "${irisversions}" | jq -cr '.[]'); do
		iristag="${coqtag}_iris-${irisversion}"

		docker build --squash -t "ghcr.io/katamaran-project/coq:$iristag" - <<- EOF
			FROM ghcr.io/katamaran-project/coq:$coqtag
			RUN set -x \\
			&& opam install -vyj\$(nproc) --ignore-constraints-on coq coq-iris=${irisversion} \\
			&& opam clean -acrs --logs \\
			&& opam config list && opam list
		EOF
		docker image push "ghcr.io/katamaran-project/coq:$iristag"

		for equationsversion in $(echo "${equationsversions}" | jq -cr '.[]'); do
			equationstag="$(echo "${equationsversion}" | sed 's/+.*$//')"
			equationstag="${coqtag}_iris-${irisversion}_equations-${equationstag}"

			docker build --squash -t "ghcr.io/katamaran-project/coq:$equationstag" - <<- EOF
				FROM ghcr.io/katamaran-project/coq:$iristag
				RUN set -x \\
				&& opam install -vyj\$(nproc) coq-equations=${equationsversion} \\
				&& opam clean -acrs --logs \\
				&& opam config list && opam list
			EOF
			docker image push "ghcr.io/katamaran-project/coq:$equationstag"
		done
	done
done
