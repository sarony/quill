class ProfilesController < ApplicationController
  before_filter :signed_in!

  def show
    @user = current_user
    send current_user.role
  end

  def update
    @user = current_user
    @user.update_attributes(user_params)
    redirect_to profile_path
  end

  def user
    student
  end

  def student
    @classroom = current_user.classroom

    @activity_table = {
      false => {},
      true => {}
    }

    @classroom.units.each do |unit|
      # raise @classroom.classroom_activities.map(&:assigned_student_ids)

      activities = unit.activities.includes(:classroom_activities).where(<<-SQL, current_user.id)
      classroom_activities.assigned_student_ids IS NULL OR
      classroom_activities.assigned_student_ids = '{}' OR
      ? = ANY (classroom_activities.assigned_student_ids)
      SQL

      activities.each do |activity|
        activity_session = ActivitySession.joins(:classroom_activity).where(
          'classroom_activities.activity_id = ? AND classroom_activities.classroom_id = ? AND activity_sessions.user_id = ?',
          activity.id,
          @classroom.id,
          current_user.id).first


        key = activity_session.try(:state) == 'finished'

        @activity_table[key][unit.name] ||= {}
        @activity_table[key][unit.name][activity.topic.name] ||= []
        @activity_table[key][unit.name][activity.topic.name] << activity
      end
    end

    render :student
  end

  def teacher
    redirect_to teachers_classrooms_path
  end

  def admin
    render :admin
  end

protected
  def user_params
    params.require(:user).permit(:classcode, :email, :name, :username, :password, :password_confirmation)
  end
end
