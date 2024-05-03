extends CenterContainer


@onready var TextOutput = get_child(0)

func debugPrint (input = ""):
	TextOutput.set_text(TextOutput.get_text() + "\n" + input)
