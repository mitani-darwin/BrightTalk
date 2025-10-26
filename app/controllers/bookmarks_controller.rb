class BookmarksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, except: [:index]

  def index
    @bookmarks = current_user.bookmarks
                             .includes(post: [:user, :category, :tags, :likes, :bookmarks])
                             .order(created_at: :desc)
    @posts = @bookmarks.map(&:post).compact
  end

  def create
    existing_bookmark = current_user.bookmarks.find_by(post: @post)

    if existing_bookmark
      respond_to do |format|
        format.html { render partial: "bookmarks/bookmark_button", locals: { post: @post }, layout: false }
        format.turbo_stream
        format.json { render json: { status: "already_bookmarked", bookmarks_count: @post.bookmarks.count } }
      end
      return
    end

    @bookmark = current_user.bookmarks.build(post: @post)

    if @bookmark.save
      respond_to do |format|
        format.html { render partial: "bookmarks/bookmark_button", locals: { post: @post }, layout: false }
        format.turbo_stream
        format.json { render json: { status: "created", bookmarks_count: @post.bookmarks.count } }
      end
    else
      Rails.logger.error "Bookmark save failed: #{@bookmark.errors.full_messages.join(', ')}"

      respond_to do |format|
        format.html { render partial: "bookmarks/bookmark_button", locals: { post: @post }, layout: false, status: :unprocessable_entity }
        format.json { render json: { status: "error", errors: @bookmark.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])

    unless @bookmark.user == current_user
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, alert: "権限がありません。") }
        format.json { render json: { status: "error", message: "Unauthorized" }, status: :unauthorized }
      end
      return
    end

    unless @bookmark.post == @post
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, alert: "無効なリクエストです。") }
        format.json { render json: { status: "error", message: "Bookmark does not belong to this post" }, status: :bad_request }
      end
      return
    end

    if @bookmark.destroy
      respond_to do |format|
        format.html { render partial: "bookmarks/bookmark_button", locals: { post: @post }, layout: false }
        format.turbo_stream
        format.json { render json: { status: "destroyed", bookmarks_count: @post.bookmarks.count } }
      end
    else
      Rails.logger.error "Bookmark destroy failed: #{@bookmark.errors.full_messages.join(', ')}"
      respond_to do |format|
        format.html { render partial: "bookmarks/bookmark_button", locals: { post: @post }, layout: false, status: :unprocessable_entity }
        format.json { render json: { status: "error", errors: @bookmark.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Bookmark not found: #{params[:id]}"
    respond_to do |format|
      format.html { redirect_back(fallback_location: @post, alert: "ブックマークが見つかりませんでした。") }
      format.json { render json: { status: "error", message: "Bookmark not found" }, status: :not_found }
    end
  end

  private

  def set_post
    @post = Post.friendly.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Post not found: #{params[:post_id]}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "投稿が見つかりませんでした。" }
      format.json { render json: { status: "error", message: "Post not found" }, status: :not_found }
    end
  end
end
