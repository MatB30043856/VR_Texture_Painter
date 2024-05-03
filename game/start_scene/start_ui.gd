extends CenterContainer
# File Dialog interaction code based on tutorial by iaknihs, accessed on 28/04/2024
# https://youtu.be/XYiCdOfy3J8

func _on_load_existing_model_pressed():
	$ModelFileDialog.popup()

func _on_model_file_dialog_file_selected(path):
	%Loaded_Model.load_model(path)
	
