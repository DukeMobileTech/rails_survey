# frozen_string_literal: true

module ActiveAdmin
  class CommentPolicy < ApplicationPolicy
    class Scope < Struct.new(:user, :scope)
      def resolve
        scope
      end
    end

    def index?
      @user.admin_user?
    end

    def show?
      @user.admin_user?
    end

    def create?
      @user.admin_user?
    end

    def update?
      @user.admin_user?
    end

    def destroy?
      @user.admin_user?
    end
  end
end