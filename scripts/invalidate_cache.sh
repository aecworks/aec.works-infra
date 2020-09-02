#!/bin/bash

DISTRIBUTION_ID=ERIO26AYCDCNL
aws cloudfront create-invalidation --distribution-id "${DISTRIBUTION_ID}"  --path "/*"
