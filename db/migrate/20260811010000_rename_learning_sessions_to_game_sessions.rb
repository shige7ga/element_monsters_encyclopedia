class RenameLearningSessionsToGameSessions < ActiveRecord::Migration[8.1]
  def change
    rename_table :learning_sessions, :game_sessions
  end
end
