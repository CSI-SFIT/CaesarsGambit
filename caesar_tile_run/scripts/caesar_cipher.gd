extends RefCounted
class_name CaesarCipher

# Latin word bank suitable for Ancient Rome theme
const ROMAN_WORDS: Array[String] = [
	"ROMA", "VENI", "VICI", "AUREUS", "GLADIO", "LEGIO", "SENATUS", 
	"CAESAR", "FORUM", "MAXIMUS", "TEMPLUM", "VICTORIA"
]

const ALPHABET: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

static func encrypt(text: String, shift: int) -> String:
	var result: String = ""
	text = text.to_upper()
	for i in range(text.length()):
		var ch: String = text[i]
		var idx: int = ALPHABET.find(ch)
		if idx != -1:
			var new_idx: int = (idx + shift) % 26
			if new_idx < 0:
				new_idx += 26
			result += ALPHABET[new_idx]
		else:
			result += ch
	return result

static func decrypt(text: String, shift: int) -> String:
	return encrypt(text, -shift)

# Generates a puzzle: returns a dictionary with:
# { "plain_word": String, "cipher_word": String, "shift": int, "path_columns": Array[int], "grid_letters": Array[Array] }
static func generate_puzzle(rows: int, cols: int) -> Dictionary:
	var word: String = ROMAN_WORDS[randi() % ROMAN_WORDS.size()]
	
	# Pad or repeat word letters to match row count
	var target_letters: Array[String] = []
	for r in range(rows):
		target_letters.append(word[r % word.length()])
	
	# Shift between 1 and 5 (classic Caesar range)
	var shift: int = (randi() % 5) + 1
	var cipher_letters: Array[String] = []
	for letter in target_letters:
		cipher_letters.append(encrypt(letter, shift))
	
	# Generate continuous traversable path (adjacent tiles per row)
	var path_cols: Array[int] = []
	var curr_col: int = randi() % cols
	path_cols.append(curr_col)
	for r in range(1, rows):
		var delta_choices: Array[int] = [0]
		if curr_col > 0:
			delta_choices.append(-1)
		if curr_col < cols - 1:
			delta_choices.append(1)
		var delta: int = delta_choices[randi() % delta_choices.size()]
		curr_col += delta
		path_cols.append(curr_col)
	
	# Generate letter grid
	var grid_letters: Array = []
	for r in range(rows):
		var row_chars: Array[String] = []
		var safe_char: String = target_letters[r]
		for c in range(cols):
			if c == path_cols[r]:
				row_chars.append(safe_char)
			else:
				# Generate random distractor different from safe_char
				var rand_char: String = ALPHABET[randi() % ALPHABET.length()]
				while rand_char == safe_char:
					rand_char = ALPHABET[randi() % ALPHABET.length()]
				row_chars.append(rand_char)
		grid_letters.append(row_chars)
		
	var cipher_word: String = "".join(cipher_letters)
	var plain_word: String = "".join(target_letters)
	
	return {
		"plain_word": plain_word,
		"cipher_word": cipher_word,
		"shift": shift,
		"path_cols": path_cols,
		"grid_letters": grid_letters
	}
