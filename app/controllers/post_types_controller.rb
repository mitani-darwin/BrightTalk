class PostTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post_type, only: [:show, :edit, :update, :destroy]

  def index
    @post_types = PostType.all.order(:name)
    
    respond_to do |format|
      format.json do
        render json: {
          post_types: @post_types.map { |pt| 
            { 
              id: pt.id, 
              name: pt.name, 
              description: pt.description,
              posts_count: pt.posts_count
            } 
          }
        }
      end
      format.html
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: {
          post_type: {
            id: @post_type.id,
            name: @post_type.name,
            description: @post_type.description,
            posts_count: @post_type.posts_count
          }
        }
      end
      format.html
    end
  end

  def new
    @post_type = PostType.new
  end

  def create
    @post_type = PostType.new(post_type_params)

    if @post_type.save
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            post_type: {
              id: @post_type.id,
              name: @post_type.name,
              description: @post_type.description,
              posts_count: @post_type.posts_count
            },
            message: "投稿タイプ「#{@post_type.name}」を作成しました"
          }
        end
        format.html { redirect_to post_types_path, notice: '投稿タイプが作成されました。' }
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: @post_type.errors.full_messages,
            message: "投稿タイプの作成に失敗しました"
          }, status: :unprocessable_content
        end
        format.html do
          render :new, status: :unprocessable_content
        end
      end
    end
  end

  def edit
  end

  def update
    if @post_type.update(post_type_params)
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            post_type: {
              id: @post_type.id,
              name: @post_type.name,
              description: @post_type.description,
              posts_count: @post_type.posts_count
            },
            message: "投稿タイプ「#{@post_type.name}」を更新しました"
          }
        end
        format.html { redirect_to post_types_path, notice: '投稿タイプが更新されました。' }
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: @post_type.errors.full_messages,
            message: "投稿タイプの更新に失敗しました"
          }, status: :unprocessable_content
        end
        format.html do
          render :edit, status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    if @post_type.posts.any?
      message = "この投稿タイプを使用している投稿が存在するため削除できません"
      respond_to do |format|
        format.json { render json: { success: false, message: message }, status: :unprocessable_content }
        format.html { redirect_to post_types_path, alert: message }
      end
    else
      @post_type.destroy
      respond_to do |format|
        format.json { render json: { success: true, message: "投稿タイプ「#{@post_type.name}」を削除しました" } }
        format.html { redirect_to post_types_path, notice: '投稿タイプが削除されました。' }
      end
    end
  end

  private

  def set_post_type
    @post_type = PostType.find(params[:id])
  end

  def post_type_params
    params.require(:post_type).permit(:name, :description)
  end
end