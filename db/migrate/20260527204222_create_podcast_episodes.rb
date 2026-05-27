class CreatePodcastEpisodes < ActiveRecord::Migration[8.1]
  def change
    create_table :podcast_episodes do |t|
      t.string   :title,            null: false
      t.string   :slug,             null: false
      t.integer  :season,           null: false, default: 1
      t.integer  :episode_number,   null: false
      t.text     :description
      t.string   :audio_url
      t.string   :video_url
      t.integer  :duration_seconds
      t.string   :guest_names,      array: true, default: []
      t.text     :transcript
      t.date     :scheduled_for
      t.datetime :published_at
      t.string   :cover_photo_slug

      t.timestamps
    end

    add_index :podcast_episodes, :slug, unique: true
    add_index :podcast_episodes, [ :season, :episode_number ], unique: true
    add_index :podcast_episodes, :published_at
  end
end
