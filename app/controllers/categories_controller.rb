# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [ :show, :edit, :update, :destroy ]

  def index
    @root_categories = Category.root_categories.includes(:children).order(:name)

    respond_to do |format|
      format.json do
        render json: {
          categories: build_hierarchical_categories(@root_categories)
        }
      end
      format.html
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: {
          category: category_with_hierarchy(@category)
        }
      end
      format.html
    end
  end

  def new
    @category = Category.new
    @parent_categories = Category.all.order(:name)
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            category: category_with_hierarchy(@category),
            message: "カテゴリー「#{@category.name}」を作成しました"
          }
        end
        format.html { redirect_to categories_path, notice: "カテゴリーが作成されました。" }
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: @category.errors.full_messages,
            message: "カテゴリーの作成に失敗しました"
          }, status: :unprocessable_content
        end
        format.html do
          @parent_categories = Category.all.order(:name)
          render :new, status: :unprocessable_content
        end
      end
    end
  end

  def edit
    @parent_categories = Category.where.not(id: [ @category.id ] + @category.descendants.pluck(:id)).order(:name)
  end

  def update
    if @category.update(category_params)
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            category: category_with_hierarchy(@category),
            message: "カテゴリー「#{@category.name}」を更新しました"
          }
        end
        format.html { redirect_to categories_path, notice: "カテゴリーが更新されました。" }
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: @category.errors.full_messages,
            message: "カテゴリーの更新に失敗しました"
          }, status: :unprocessable_content
        end
        format.html do
          @parent_categories = Category.where.not(id: [ @category.id ] + @category.descendants.pluck(:id)).order(:name)
          render :edit, status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    if @category.children.any?
      message = "サブカテゴリーが存在するため削除できません"
      respond_to do |format|
        format.json { render json: { success: false, message: message }, status: :unprocessable_content }
        format.html { redirect_to categories_path, alert: message }
      end
    else
      @category.destroy
      respond_to do |format|
        format.json { render json: { success: true, message: "カテゴリー「#{@category.name}」を削除しました" } }
        format.html { redirect_to categories_path, notice: "カテゴリーが削除されました。" }
      end
    end
  end

  def children
    render json: {
      children: @category.children.order(:name).map { |c|
        {
          id: c.id,
          name: c.name,
          description: c.description,
          full_name: c.full_name
        }
      }
    }
  end

  def hierarchical
    @root_categories = Category.root_categories.includes(:children).order(:name)
    render json: {
      categories: build_hierarchical_categories(@root_categories)
    }
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :description, :parent_id)
  end

  def build_hierarchical_categories(categories)
    categories.map do |category|
      {
        id: category.id,
        name: category.name,
        description: category.description,
        parent_id: category.parent_id,
        full_name: category.full_name,
        depth: category.depth,
        children: build_hierarchical_categories(category.children.order(:name))
      }
    end
  end

  def category_with_hierarchy(category)
    {
      id: category.id,
      name: category.name,
      description: category.description,
      parent_id: category.parent_id,
      full_name: category.full_name,
      depth: category.depth,
      ancestors: category.ancestors.map { |c| { id: c.id, name: c.name } },
      children: category.children.map { |c| { id: c.id, name: c.name } }
    }
  end
end
