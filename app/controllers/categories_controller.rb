# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  before_action :authenticate_user!

  def create
    @category = Category.new(category_params)

    if @category.save
      render json: {
        success: true,
        category: {
          id: @category.id,
          name: @category.name
        },
        message: "カテゴリー「#{@category.name}」を作成しました"
      }
    else
      render json: {
        success: false,
        errors: @category.errors.full_messages,
        message: "カテゴリーの作成に失敗しました"
      }, status: :unprocessable_entity
    end
  end

  def index
    @categories = Category.all.order(:name)
    render json: {
      categories: @categories.map { |c| { id: c.id, name: c.name } }
    }
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end
end