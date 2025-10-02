# syntax=docker/dockerfile:1
FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       python3-colcon-common-extensions \
       build-essential \
       ros-dev-tools \
       ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
       ros-${ROS_DISTRO}-xacro \
       sudo \
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN set -eux; \
    if getent group "${USER_GID}" >/dev/null; then \
      EXISTING_GROUP=$(getent group "${USER_GID}" | cut -d: -f1); \
      if [ "${EXISTING_GROUP}" != "${USERNAME}" ]; then \
        groupmod --new-name "${USERNAME}" "${EXISTING_GROUP}"; \
      fi; \
    elif getent group "${USERNAME}" >/dev/null; then \
      groupmod --gid "${USER_GID}" "${USERNAME}"; \
    else \
      groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    if getent passwd "${USER_UID}" >/dev/null; then \
      EXISTING_USER=$(getent passwd "${USER_UID}" | cut -d: -f1); \
      if [ "${EXISTING_USER}" != "${USERNAME}" ]; then \
        usermod --login "${USERNAME}" --move-home --home "/home/${USERNAME}" "${EXISTING_USER}"; \
      fi; \
      usermod --uid "${USER_UID}" --gid "${USER_GID}" "${USERNAME}"; \
    elif id -u "${USERNAME}" >/dev/null 2>&1; then \
      usermod --uid "${USER_UID}" --gid "${USER_GID}" "${USERNAME}"; \
      usermod --home "/home/${USERNAME}" --move-home "${USERNAME}"; \
    else \
      useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home "${USERNAME}"; \
    fi

ENV ROS_WS=/ros2_ws \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
RUN mkdir -p ${ROS_WS}/src \
    && chown -R ${USERNAME}:${USERNAME} ${ROS_WS}

WORKDIR ${ROS_WS}

COPY ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh

RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
