#!/bin/bash

git pull
jumppad --non-interactive up \
--var "docs_url=https://debian-80-${INSTRUQT_PARTICIPANT_ID}.env.play.instruqt.com" \
--var "base_url=debian.${INSTRUQT_PARTICIPANT_ID}.instruqt.io" \
./jumppad