#!/bin/bash

PROJECT=fga

set -e

inserts=(
    "insert into all_objects values
      ('u/specialmod','{\"legalCountryCode\": \"us\"}'),
      ('u/catperson', '{\"legalCountryCode\": \"us\"}'),
      ('u/randomcontributor', '{\"legalCountryCode\": \"us\"}'),
      ('u/russianperson', '{\"legalCountryCode\": \"ru\"}'),
      ('r/dogs', '{\"deleted\": true, \"spam\": true, \"type\": \"private\", \"legalBlock\": null}'),
      ('r/cats', '{\"deleted\": false, \"spam\": false, \"type\": \"private\", \"legalBlock\": {\"countryCode\": \"ru\"}}'),
      ('u/socialperson', '{\"type\": \"user\", \"deleted\": false, \"spam\": false}'),
      ('r/norussians', '{\"deleted\": false, \"spam\": false, \"type\": \"public\", \"legalBlock\": {\"countryCode\": \"ru\"}}'),
      ('r/random', '{\"deleted\": false, \"spam\": false, \"type\": \"private\", \"legalBlock\": null}'),
      ('1234', '{}');"
    "insert into active_objects values
      ('u/specialmod'),
      ('u/catperson'),
      ('u/randomcontributor'),
      ('u/russianperson'),
      ('r/dogs'),
      ('r/cats'),
      ('u/socialperson'),
      ('r/norussians'),
      ('r/random'),
      ('1234');"
    "insert into edges values
      ('u/specialmod', 'r/dogs', 'moderator'),
      ('u/catperson', 'r/cats', 'subscribed'),
      ('u/randomcontributor', 'r/random', 'contributor'),
      ('r/random', '1234', 'subreddit');"
    "insert into unary_rules values
      ('moderator', '\`true\`', 'can_view'),
      ('contributor', 'resource.deleted != \`true\` && resource.spam != \`true\` && subject.banned != \`true\` && subject.legalCountryCode != resource.legalBlock.countryCode', 'can_view'),
      ('subscribed', 'resource.deleted != \`true\` && resource.spam != \`true\` && subject.banned != \`true\` && subject.legalCountryCode != resource.legalBlock.countryCode', 'can_view'),
      ('author', '\`true\`', 'can_edit'),
      ('can_edit', '\`true\`', 'can_view');"
    "insert into binary_rules values
      ('can_view', 'subreddit', '\`true\`', 'can_view');"
)

fda shutdown $PROJECT || true
fda del $PROJECT || true

fda create $PROJECT fga.sql --udf-rs fga.rs --udf-toml fga.toml
fda start $PROJECT

for query in "${inserts[@]}"; do
    fda query fga "$query"
done

fda query fga "select * from relationships;"
