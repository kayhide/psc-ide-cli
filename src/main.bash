source prelude.bash

IDE_SERVER_PORT="${PSC_IDE_SERVER_PORT:-$(ps -eo cmd |sed -n "s/.*purs ide .*\(-p\|--port\) \+\([0-9]\+\).*/\2/p" |grep -v "^0$")}"

if [[ -z $IDE_SERVER_PORT ]]; then
    die "IDE server is not running"
elif (( 1 < $(echo "$IDE_SERVER_PORT" |wc -l) )); then
    die "More than one IDE server is running"
fi

request() {
    jq -c |nc localhost "$IDE_SERVER_PORT"
}

build_add_import() {
    local file="$1"
    local identifier="${2:-}"
    local qualifier="${3:-}"
    local module="${4:-}"

    if [[ -n $module && -n $qualifier ]]; then
        cat <<EOF
{
    "command": "import",
    "params": {
        "file": "$file",
        "importCommand": {
            "importCommand": "addQualifiedImport",
            "module": "$module",
            "qualifier": "$qualifier"
        }}
}
EOF
    else
        cat <<EOF |add_qualifier "$qualifier" |add_filters "$module"
{
    "command": "import",
    "params": {
        "file": "$file",
        "importCommand": {
            "importCommand": "addImport",
            "identifier": "$identifier"
        }
    }
}
EOF
    fi
}

add_qualifier() {
    local qualifier="${1:-}"
    if [[ -z $qualifier ]]; then
        jq .
    else
        (cat; cat <<EOF) | jq -s '.[0] * .[1]'
{
    "params": {
        "importCommand": {
            "qualifier": "$qualifier"
        }
    }
}
EOF
    fi
}

add_filters() {
    local module="${1:-}"
    if [[ -z $module ]]; then
        jq .
    else
        (cat; cat <<EOF) | jq -s '.[0] * .[1]'
{
    "params": {
        "filters": [{
            "filter": "modules",
            "params": {
                "modules": ["$module"]
            }
        }]
    }
}
EOF
    fi
}

parse_result() {
    local res
    res="$(jq)"
    if echo "$res" | jq ".resultType" >/dev/null 2>&1; then
        if [[ $(echo "$res" | jq -r ".resultType") != success ]]; then
            die "$(echo "$res" | jq -r ".result")"
        elif [[ $(echo $res | jq ".result") =~ Written ]]; then
            echo
        elif echo "$res" | jq -r ".result[0].module" >/dev/null 2>&1; then
            echo "$res" | jq -r ".result[].module"
            exit 2
        else
            echo "$res" | jq -r ".result[]"
        fi
    fi
}

declare -a args
declare -A opts
parse_args "$@"

if [[ -n $(lookup_opt version) ]]; then
    echo "$VERSION"
    exit
fi

build_add_import "$@" |request |parse_result
