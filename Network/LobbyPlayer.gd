extends Control

func set_player_name(player_name):
	get_node("HBoxContainer/Player_Name").text = player_name

func set_player_status(status):
	get_node("HBoxContainer/Player_Status").text = status

