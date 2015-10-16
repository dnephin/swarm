#!/usr/bin/env bats

load ../helpers

function teardown() {
	swarm_manage_cleanup
	stop_docker
}

@test "docker pull" {
	start_docker 2
	swarm_manage

	# make sure no image exists
	run docker_swarm images -q
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 0 ]

	docker_swarm pull busybox

	# with grouping, we should get 1 busybox, plus the header.
	run docker_swarm images
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	# every line should contain "busybox" exclude the first head line
	for((i=1; i<${#lines[@]}; i++)); do
		[[ "${lines[i]}" == *"busybox"* ]]
	done

	# verify on the nodes
	for host in ${HOSTS[@]}; do
		run docker -H $host images
		[ "$status" -eq 0 ]
		[ "${#lines[@]}" -ge 2 ]
		[[ "${lines[1]}" == *"busybox"* ]]
	done
}

@test "docker pull -check error code" {
	start_docker 2
	swarm_manage

	run docker_swarm pull does_not_exist

	printf '%s\n' "${lines[@]}"
	[ "$status" -eq 1 ]
	[ "${#lines[@]}" -eq 5 ]
	[[ "${lines[3]}" == *"Error: image library/does_not_exist:latest not found"* ]]
	[[ "${lines[4]}" == *"Error: image library/does_not_exist:latest not found"* ]]
}
