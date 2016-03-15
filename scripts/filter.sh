basedir=$(dirname $(readlink -f "$0"))
filmsdir=$(dirname "$basedir")

people=()
verbose=false
no_plus=false
no_minus=false

while [ $# -gt 0 ]; do
	cmd="$1"
	shift

	case "$cmd" in
		--verbose|-v)
			verbose=true
		;;
		--no-plus|-p)
			no_plus=true
		;;
		--no-minus|-m)
			no_minus=true
		;;
		--)
			break
		;;
		-*)
			echo "unknown option $cmd"
			exit 0
		;;
		*)
			people+=("$cmd")
		;;
	esac
done

while [ $# -gt 0 ]; do
	people+=("$1")
	shift
done

for f in "$filmsdir"/*; do
	if [ -f "$f" ]; then
		if ! $no_minus; then
			fail=false
			for p in "${people[@]}"; do
				if [ "$(sed -e '1,/^---\+$/d' -e '/^---\+$/,$d' "$f" | grep -- "-$p")" != "" ]; then
					fail=true
					break
				fi
			done
			if $fail; then
				continue
			fi
		fi

		if ! $no_plus; then
			result=$(sed -e '1,/^---\+$/d' -e '/^---\+$/,$d' -e '/^[^+]/d' -e 's/^+//' "$f" | \
					sort -u | \
					while IFS=$'\n' read -r p; do
						if [[ ! "${people[@]}" =~ "$p" ]]; then
							echo "$p"
						fi
					done)
			if [ "$result" != "" ]; then
				continue
			fi
		fi

		# count votes
		vote_stats=$(sed -e '1,/^---\+$/d' -e '/^---\+$/,$d' "$f" \
				| awk 'BEGIN{p=0; m=0} /^+/{p++} /^-/{m++} END{print p":"m}')

		if $verbose; then
			echo "--- [$vote_stats] ${f##*/} ---"
			sed -e '/^---\+$/,$d' "$f"
			echo
		else
			echo "$vote_stats ${f##*/}"
		fi
	fi
done
