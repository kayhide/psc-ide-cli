import prelude.bash

IDE_SERVER_PORT="$(ps -eo cmd |sed -n "s/.*-p \([0-9]\+\).*/\1/p")"

if [[ -z $IDE_SERVER_PORT ]]; then
    die "IDE server is not running"
fi

request() {
     jq -c |nc localhost "$IDE_SERVER_PORT"
}

build_add_import() {
    local file="$1"
    local identifier="$2"
    local qualifier="${3:-}"
    local module="${4:-}"

    cat <<EOF |add_qualifier "$qualifier" |add_filters "$module"
{
    "command": "import",
    "params": {
        "file": "$file",
        "outfile": "$file",
        "importCommand": {
            "importCommand": "addImport",
            "identifier": "$identifier"
        }
    }
}
EOF
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
    if [[ $(echo $res | jq ".result") =~ Written ]]; then
        echo
    else
        echo "$res" |jq -r ".result[].module"
    fi
}

parse_args "$@"

if [[ -n $(lookup_opt version) ]]; then
    echo "$VERSION"
    exit
fi

build_add_import "$@" |request |parse_result
