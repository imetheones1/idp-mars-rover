extends Node

var pathfinding_flatness_weight:float = 5
var pathfinding_lateral_weight:float = 10

var rover_pathing_speed:float = 4

signal heightmap_created(heightmap_image: Image)

var created_heightmap := false
var created_heightmap_image:Image
