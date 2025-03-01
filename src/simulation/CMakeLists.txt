cmake_minimum_required(VERSION 3.5)

project(simulation)

find_package(ament_cmake REQUIRED)
# find_package(rclcpp REQUIRED)
# find_package(rclcpp_action REQUIRED)
# find_package(gazebo_msgs REQUIRED)
# find_package(openmind_interfaces REQUIRED)
# find_package(message_filters REQUIRED)
# find_package(sensor_msgs REQUIRED)
# find_package(yaml-cpp REQUIRED)

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

# install(DIRECTORY robots/g1_description
#   DESTINATION share/${PROJECT_NAME}/robots
# )

# Export package
ament_package()

