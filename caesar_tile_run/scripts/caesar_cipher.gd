extends RefCounted
class_name CaesarCipher

# Latin word bank suitable for Ancient Rome theme
const ROMAN_WORDS: Array[String] = [
	"CENTURIO", "IMPERIUM", "COLOSSEUM", "GLADIATOR", "AQUILA", 
	"TIBERIUS", "AUGUSTUS", "TRIUMPHUS", "PRAETOR", "LEGIONIS", 
	"PATRICIAN", "DOMINUS", "VALENTIA", "VITTORIA", "CAESAR", "SENATUS"
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

# Generates a puzzle: returns dictionary with:
# { "plain_word": String, "cipher_word": String, "shift": int, "path_cols": Array[int], "grid_letters": Array[Array] }
static func generate_puzzle(rows: int, cols: int) -> Dictionary:
	var word: String = ROMAN_WORDS[randi() % ROMAN_WORDS.size()]
	
	var target_letters: Array[String] = []
	for r in range(rows):
		target_letters.append(word[r % word.length()])
	
	# Strictly positive Caesar shift (+2 to +5) - no confusing negative numbers!
	var shift: int = (randi() % 4) + 2
	
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
	
	# Generate letter grid with authentic deceptive distractors
	var grid_letters: Array = []
	for r in range(rows):
		var row_chars: Array[String] = []
		var safe_char: String = target_letters[r]
		var cipher_char: String = cipher_letters[r]
		
		var decoy_off_by_one: String = encrypt(safe_char, 1)
		var decoy_cipher_trap: String = cipher_char
		
		var used_chars: Dictionary = { safe_char: true }
		
		for c in range(cols):
			if c == path_cols[r]:
				row_chars.append(safe_char)
			else:
				var candidate: String = ""
				if c == (path_cols[r] + 1) % cols and not used_chars.has(decoy_off_by_one):
					candidate = decoy_off_by_one
				elif c == (path_cols[r] + 2) % cols and not used_chars.has(decoy_cipher_trap):
					candidate = decoy_cipher_trap
				else:
					candidate = ALPHABET[randi() % ALPHABET.length()]
					while used_chars.has(candidate):
						candidate = ALPHABET[randi() % ALPHABET.length()]
						
				used_chars[candidate] = true
				row_chars.append(candidate)
				
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
