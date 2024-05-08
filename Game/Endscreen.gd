extends PanelContainer

signal go_back

func set_winner(winner:String):
	$VBoxContainer/Winner.text = winner

func _on_button_pressed():
	go_back.emit()
