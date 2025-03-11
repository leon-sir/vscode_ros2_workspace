from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import (DeclareLaunchArgument, SetEnvironmentVariable, 
                            IncludeLaunchDescription, SetLaunchConfiguration)
from launch.substitutions import PathJoinSubstitution, LaunchConfiguration, TextSubstitution
from launch_ros.actions import Node
from launch.launch_description_sources import PythonLaunchDescriptionSource
import os
from launch.actions import ExecuteProcess, RegisterEventHandler

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

    sim_package = os.path.join(
        get_package_share_directory('simulation'))
    
    # world path
    world_path = os.path.join(sim_package,
                              'world',
                              'my_world.world')
    # # robot path

    # urdf_file = os.path.join(sim_package,
    #     'robots',
    #     'g1_description',
    #     'g1_23dof.urdf'
    # )
    # with open(urdf_file, 'r') as infp:
    #     robot_desc = infp.read()
    
    urdf_file = os.path.join(sim_package,
        'robots',
        'flying_robot_urdf',
        'flying_robot_urdf.urdf'
    )
    with open(urdf_file, 'r') as infp:
        robot_desc = infp.read()
    
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

    spawn_entity_node = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        arguments=['-entity', 'flying_robot', '-file', urdf_file],
        output='screen'
    )

    # pkg_ros_gz_sim = get_package_share_directory('ros_gz_sim')
    # pkg_spaceros_gz_sim = get_package_share_directory('spaceros_gz_sim')
    # gz_launch_path = PathJoinSubstitution([pkg_ros_gz_sim, 'launch', 'gz_sim.launch.py'])
    # gz_model_path = PathJoinSubstitution([pkg_spaceros_gz_sim, 'models'])

    return LaunchDescription([
        start_gazebo_cmd,
        robot_state_publisher_node,
        spawn_entity_node
        

    ])