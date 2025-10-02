#!/bin/bash
set -e

# ROS 2セットアップを読み込む
source "/opt/ros/${ROS_DISTRO}/setup.bash"

ROS_WS=${ROS_WS:-/ros2_ws}
if [ -f "${ROS_WS}/install/setup.bash" ]; then
  source "${ROS_WS}/install/setup.bash"
fi

exec "$@"
