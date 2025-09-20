class FeedsController < ApplicationController
  before_action :set_posts

  def rss
    respond_to do |format|
      format.rss { render layout: false }
      format.xml { render action: :rss, layout: false }
    end
  end

  def atom
    respond_to do |format|
      format.atom { render layout: false }
      format.xml { render action: :atom, layout: false }
    end
  end

  private

  def set_posts
    @posts = Post.published_posts
                 .includes(:user, :category, :tags)
                 .recent
                 .limit(20)
  end
end