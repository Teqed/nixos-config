#!/usr/bin/env bash
pecho() { # Print with a newline
    for arg ; do
        echo "${arg//[:;]/\n\n}" ;
    done
}