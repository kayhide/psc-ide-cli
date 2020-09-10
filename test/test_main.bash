ROOT_DIR="$(cd "$(dirname $0)/.." && pwd)"
PATH="$ROOT_DIR/src:$ROOT_DIR/bin:$PATH"

FIXTURES_DIR="$ROOT_DIR/test/fixtures"
GOLDEN_DIR="$ROOT_DIR/test/golden"

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
    local file="$FIXTURES_DIR/spago-project/src/Main.purs"
    local result="$(psc-ide-cli "$file" log)"
    local expected="$(cat <<EOF
Effect.Class.Console
Effect.Console
EOF
    )"
    assertEquals "$expected" "$result"
}

testIdentifierNotFound() {
    local file="$FIXTURES_DIR/spago-project/src/Main.purs"
    assertFalse "psc-ide-cli "$file" nosuchthing"

    local result="$(psc-ide-cli "$file" nosuchthing 2>&1)"
    assertContains "$result" "Couldn't find the given identifier."
}

testIdentifierWithModule() {
    local file="$FIXTURES_DIR/spago-project/src/Main.purs"
    local result="$(psc-ide-cli "$file" log '' Effect.Console)"
    assertEquals "$result" "$(cat "$GOLDEN_DIR/Main-EffectConsole_log.purs")"
}

. shunit2
