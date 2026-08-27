class LearningController < ApplicationController
  QUESTION_COUNT = 10

  # 学習機能を追加しやすいよう、クイズ開始前の入口を分離する。
  def index
    @game_session_count = current_user&.game_sessions&.count || 0
  end

  def show
    @quiz = quiz_state || start_quiz
    return unless @quiz

    load_current_question
  end

  def answer
    quiz = quiz_state || start_quiz
    return redirect_to learning_quiz_path unless quiz
    return redirect_to learning_quiz_path if quiz["answered"]

    element = current_element(quiz)
    selected_element_id = params[:element_id].to_i
    correct = selected_element_id == element.id

    quiz["selected_element_id"] = selected_element_id
    quiz["correct"] = correct
    quiz["answered"] = true
    quiz["score"] += 1 if correct
    save_quiz(quiz)

    redirect_to learning_quiz_path
  end

  def next_question
    quiz = quiz_state
    return redirect_to learning_quiz_path unless quiz&.fetch("answered", false)

    if quiz["current_index"] + 1 >= quiz["element_ids"].length
      quiz["completed"] = true
      save_quiz(quiz)
      persist_game_session(quiz)
      redirect_to learning_result_path
    else
      quiz["current_index"] += 1
      quiz["answered"] = false
      quiz.delete("selected_element_id")
      quiz.delete("correct")
      save_quiz(quiz)
      redirect_to learning_quiz_path
    end
  end

  def result
    @quiz = quiz_state
    return redirect_to learning_path unless @quiz&.fetch("completed", false)

    @game_session = persist_game_session(@quiz)
    @accuracy_percentage = (@quiz["score"].fdiv(@quiz["element_ids"].length) * 100).round
  end

  def restart
    session.delete(:learning_quiz)
    redirect_to learning_quiz_path
  end

  private

  def load_current_question
    @element = current_element(@quiz)
    @choices = choices_for(@quiz, @element)
    @illustration = @element.illustrations.published.with_attached_image.order(Arel.sql("RANDOM()")).first
    @question_number = @quiz["current_index"] + 1
    @answered = @quiz["answered"]
    @selected_element_id = @quiz["selected_element_id"]
    @correct = @quiz["correct"]
  end

  def start_quiz
    element_ids = random_question_ids

    if element_ids.length < QUESTION_COUNT
      flash[:alert] = t("flash.learning.insufficient_elements", count: QUESTION_COUNT)
      return
    end

    quiz = {
      "element_ids" => element_ids,
      "choice_ids" => {},
      "current_index" => 0,
      "score" => 0,
      "answered" => false,
      "completed" => false
    }
    save_quiz(quiz)
    quiz
  end

  def random_question_ids
    Element.order(Arel.sql("RANDOM()")).limit(QUESTION_COUNT).pluck(:id)
  end

  def choices_for(quiz, element)
    question_key = quiz["current_index"].to_s
    choice_ids = quiz["choice_ids"][question_key]

    unless choice_ids
      incorrect_ids = Element.where.not(id: element.id).order(Arel.sql("RANDOM()")).limit(3).pluck(:id)
      choice_ids = ([ element.id ] + incorrect_ids).shuffle
      quiz["choice_ids"][question_key] = choice_ids
      save_quiz(quiz)
    end

    elements_by_id = Element.where(id: choice_ids).index_by(&:id)
    choice_ids.map { |id| elements_by_id.fetch(id) }
  end

  def current_element(quiz)
    Element.find(quiz["element_ids"][quiz["current_index"]])
  end

  def quiz_state
    session[:learning_quiz]
  end

  def save_quiz(quiz)
    session[:learning_quiz] = quiz
  end

  def persist_game_session(quiz)
    return unless user_signed_in?

    if quiz["game_session_id"]
      return current_user.game_sessions.find_by(id: quiz["game_session_id"])
    end

    game_session = current_user.game_sessions.create!(
      score: quiz["score"],
      total_questions: quiz["element_ids"].length
    )
    quiz["game_session_id"] = game_session.id
    save_quiz(quiz)
    game_session
  end
end
