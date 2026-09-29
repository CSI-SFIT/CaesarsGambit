extends Control

signal problem_solved

var current_problem: int = 1
var answers = [0, 1, 1]
var questions = [
	"Problem 1: What is (1 AND 0)?",
	"Problem 2: What is (1 OR 0)?",
	"Problem 3: What is NOT 0?"
]

@onready var question_label = %QuestionLabel
@onready var answer_input = %AnswerInput
@onready var feedback_label = %FeedbackLabel
@onready var submit_button = %SubmitButton

func _ready():
	visible = false  # Explicitly hidden at start during camera fly-in
	submit_button.pressed.connect(_on_submit_pressed)

func display_current_question():
	if current_problem <= 3:
		question_label.text = questions[current_problem - 1]
		answer_input.text = ""
		feedback_label.text = ""
		visible = true

func _on_submit_pressed():
	var user_ans = answer_input.text.strip_edges()
	if user_ans != "0" and user_ans != "1":
		feedback_label.text = "Please enter 0 or 1!"
		return
		
	if int(user_ans) == answers[current_problem - 1]:
		feedback_label.text = "Correct!"
		visible = false  # Hide UI while boulder rolls
		problem_solved.emit()
		current_problem += 1
		
		if current_problem > 3:
			question_label.text = "All logic puzzles solved!"
			answer_input.visible = false
			submit_button.visible = false
	else:
		feedback_label.text = "Incorrect, try again!"
