ROOT_DIR="$(cd "$(dirname $0)/.." && pwd)"
PATH="$ROOT_DIR/src:$ROOT_DIR/bin:$PATH"

source prelude.bash

export PSC_IDE_SERVER_PORT="$(test-server port)"
if [[ -z $PSC_IDE_SERVER_PORT ]]; then
    die <<EOF
IDE server for test is not running.
Start a test server with:
  bin/test-server up

EOF
fi

testIdentifier() {
    local file="$ROOT_DIR/test/fixtures/spago-project/src/Main.purs"
    local result="$(psc-ide-cli "$file" log)"
    local expected="$(cat <<EOF
Effect.Class.Console
Effect.Console
EOF
    )"
    assertEquals "$expected" "$result"
}


. shunit2
