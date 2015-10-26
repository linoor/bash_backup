#!/bin/tcsh
# Michał Pomarański
# grupa nr 3

function get_time_nanoseconds() {
	local result=$(date +%s%N)
	echo $result
}

function get_time() {
	local result=$(date +%H:%M:%S:%N)
	echo $result
}
