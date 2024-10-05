#!/usr/bin/bash -xe

rm -rf /tmp/* /var/*

rpm-ostree cleanup -m
ostree container commit
