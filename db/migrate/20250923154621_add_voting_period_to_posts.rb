class AddVotingPeriodToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :voting_start_date, :datetime
    add_column :posts, :voting_end_date, :datetime
  end
end
