#!/usr/bin/env bats
load test_helper

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
  dokku apps:create my_app >&2
}

teardown() {
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  rm "$DOKKU_ROOT/my_app" -rf
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the app argument is missing" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link" l
  assert_contains "${lines[*]}" "Please specify an app to run the command on"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the app does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link" l not_existing_app
  assert_contains "${lines[*]}" "App not_existing_app does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link" not_existing_service my_app
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the service is already linked to app" {
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  run dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  assert_contains "${lines[*]}" "Already linked as NATS_URL"
}

@test "($PLUGIN_COMMAND_PREFIX:link) exports NATS_URL to app" {
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  url=$(dokku config:get my_app NATS_URL)
  password="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_contains "$url" "nats://l:$password@dokku-nats-l:4222"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}

@test "($PLUGIN_COMMAND_PREFIX:link) generates an alternate config url when NATS_URL already in use" {
  dokku config:set my_app NATS_URL=nats://host:4222
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  run dokku config my_app
  assert_contains "${lines[*]}" "DOKKU_NATS_"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}

@test "($PLUGIN_COMMAND_PREFIX:link) links to app with docker-options" {
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  run dokku docker-options my_app
  assert_contains "${lines[*]}" "--link dokku.nats.l:dokku-nats-l"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}

@test "($PLUGIN_COMMAND_PREFIX:link) uses apps NATS_DATABASE_SCHEME variable" {
  dokku config:set my_app NATS_DATABASE_SCHEME=nats
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  url=$(dokku config:get my_app NATS_URL)
  password="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_contains "$url" "nats://l:$password@dokku-nats-l:4222"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}
