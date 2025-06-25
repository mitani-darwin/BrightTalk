ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # CI環境では並列実行を無効化
  if ENV['CI']
    # CI環境では並列実行しない
    parallelize(workers: 1)
  else
    # ローカル環境では並列実行
    parallelize(workers: :number_of_processors)
  end

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# ActionDispatch::IntegrationTestにDeviseのヘルパーを追加
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end