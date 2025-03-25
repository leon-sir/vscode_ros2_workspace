from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import (DeclareLaunchArgument, SetEnvironmentVariable, 
                            IncludeLaunchDescription, SetLaunchConfiguration)
from launch.substitutions import PathJoinSubstitution, LaunchConfiguration, TextSubstitution
from launch_ros.actions import Node
from launch.event_handlers import OnProcessExit
from launch.launch_description_sources import PythonLaunchDescriptionSource
import os
from launch.actions import ExecuteProcess, RegisterEventHandler

import xacro
# def generate_launch_description():
#     return LaunchDescription([
#         Node(
#             package='ros_gz_sim',
#             executable='gz_sim',
#             name='gz_sim',
#             arguments=['-r', 'empty.sdf'],  # 启动一个空的 Gazebo 世界
#             output='screen'
#         )
#     ])


def generate_launch_description():

    mappings = {
    "fix_robot": "false",
    "self_collision":"false"
    }

    sim_package = os.path.join(
        get_package_share_directory('simulation'))
    
    # world path
    world_path = os.path.join(sim_package,
                              'world',
                              'my_world.world')
    # # robot path
    xacro_file = os.path.join(sim_package,
        'robots',
        'g1_description',
        'g1_23dof.xacro'
    )

    urdf_file = os.path.join(sim_package,
        'robots',
        'g1_description',
        'g1_23dof.urdf'
    )
    doc = xacro.process_file(xacro_file,mappings=mappings)
    robot_desc = doc.toxml()
    print(robot_desc)
    # 打开文件进行写入，如果文件不存在会创建新文件
    with open(urdf_file, 'w') as file:
        file.write(doc.toprettyxml())
    
    start_gazebo_cmd = ExecuteProcess(
        cmd=['gazebo', world_path,'--verbose','-s', 'libgazebo_ros_init.so', '-s', 'libgazebo_ros_factory.so']
    )

    # 将 URDF 文件加载到参数服务器
    robot_state_publisher_node = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        name='robot_state_publisher',
        output='screen',
        parameters=[{'robot_description': robot_desc}]
    )

    ## 将机器人生成到 Gazebo 中

    # spawn_entity_node = Node(
    #     package='gazebo_ros',
    #     executable='spawn_entity.py',
    #     arguments=['-entity', 'g1_robot', '-file', urdf_file],
    #     output='screen'
    # )
    spawn_entity_node = Node(package='gazebo_ros', executable='spawn_entity.py',
                        arguments=['-topic', 'robot_description',
                                   '-entity', 'g1_robot',
                                   ],
                        output='screen')
    # spawn_entity_node = Node(package='gazebo_ros', executable='spawn_entity.py',
    #                     arguments=['-entity', 'g1_robot',
    #                                '-file', urdf_file],
    #                     output='screen')
    
    # node_joint_control_publisher = Node(
    #     package='prototype_simulation',
    #     executable='joint_control_node',
    #     name='joint_control_publisher',
    #     output='screen',
    # )
    # node_joint_control_publisher = Node(
    #     package='simulation',
    #     executable='joint_control_node',
    #     name='joint_control_publisher',
    #     output='screen',
    # )

    load_joint_state_broadcaster = ExecuteProcess(
        cmd=['ros2', 'control', 'load_controller', '--set-state', 'active',
             'joint_state_broadcaster'],
        output='screen'
    )

    load_joint_effort_controller = ExecuteProcess(
        cmd=['ros2', 'control', 'load_controller', '--set-state', 'active', 'effort_controller'],
        output='screen'
    )

    # pkg_ros_gz_sim = get_package_share_directory('ros_gz_sim')
    # pkg_spaceros_gz_sim = get_package_share_directory('spaceros_gz_sim')
    # gz_launch_path = PathJoinSubstitution([pkg_ros_gz_sim, 'launch', 'gz_sim.launch.py'])
    # gz_model_path = PathJoinSubstitution([pkg_spaceros_gz_sim, 'models'])

    return LaunchDescription([
        RegisterEventHandler(
            event_handler=OnProcessExit(
                target_action=spawn_entity_node,
                on_exit=[load_joint_state_broadcaster],
            )
        ),
        RegisterEventHandler(
            event_handler=OnProcessExit(
                target_action=load_joint_state_broadcaster,
                on_exit=[load_joint_effort_controller],
            )
        ),
        
        start_gazebo_cmd,
        robot_state_publisher_node,
        spawn_entity_node,
    ])