#!/bin/sh
cd spec/fixtures/spec-repos/test_repo
rm -rf .git || true
git init
git remote add origin https://bitbucket.com/test/test_repo.git
