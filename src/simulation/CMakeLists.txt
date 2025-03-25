cmake_minimum_required(VERSION 3.5)

project(simulation)

message(${CMAKE_SYSTEM_PROCESSOR})

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_action REQUIRED)
find_package(gazebo_msgs REQUIRED)
# controller package
# find_package(unitree_g1_interfaces REQUIRED)
find_package(message_filters REQUIRED)
# find_package(sensor_msgs REQUIRED)
find_package(yaml-cpp REQUIRED)

# 包含头文件路径
include_directories(
  ${GAZEBO_INCLUDE_DIRS}
  ${rclcpp_INCLUDE_DIRS}
  ${geometry_msgs_INCLUDE_DIRS}
  # ${sensor_msgs_INCLUDE_DIRS}
)


# install(
#   TARGETS
#     foot_force
#     joint_status_pub
#     joint_control_node
#     get_model_current_state
#     set_entity_state_client
#   DESTINATION
#     lib/${PROJECT_NAME}
# )

# Install directories (config, launch, meshes, urdf)
# install(DIRECTORY config launch meshes urdf rviz world
install(DIRECTORY launch world
  DESTINATION share/${PROJECT_NAME}
)

install(DIRECTORY robots/g1_description
  DESTINATION share/${PROJECT_NAME}/robots
)

install(DIRECTORY robots/flying_robot_urdf
  DESTINATION share/${PROJECT_NAME}/robots
)

# add_executable(joint_status_pub nodes/joint_status_pub.cpp)
# ament_target_dependencies(joint_status_pub
#   rclcpp
#   std_msgs
#   message_filters  
#   # sensor_msgs
#   yaml-cpp
#   unitree_g1_interfaces
# )

# add_executable(joint_control_node nodes/joint_control_node.cpp)
# ament_target_dependencies(joint_control_node
#   rclcpp
#   std_msgs
#   message_filters  
#   # sensor_msgs
#   gazebo_msgs
#   unitree_g1_interfaces
# )

# add_executable(joint_position_control_node nodes/joint_position_control_node.cpp)
# ament_target_dependencies(joint_position_control_node
#   rclcpp
#   std_msgs
#   message_filters  
#   # sensor_msgs
#   gazebo_msgs
#   unitree_g1_interfaces
# )

# target_link_libraries(joint_status_pub yaml-cpp)

# install(
#   TARGETS
#     joint_status_pub
#     joint_control_node
#     # chassis_control_node
#     # chassis_feedback_node
#     joint_position_control_node
#   DESTINATION
#     lib/${PROJECT_NAME}
# )

# Export package
ament_package()

