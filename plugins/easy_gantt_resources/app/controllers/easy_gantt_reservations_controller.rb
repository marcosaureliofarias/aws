class EasyGanttReservationsController < ApplicationController
  helper :easy_gantt_resources

  accept_api_auth :bulk_update_or_create, :bulk_destroy, :new, :unpersisted_reservation_info

  before_action :build_new_from_params, only: [:new, :unpersisted_reservation_info]
  before_action :find_optional_project, except: [:unpersisted_reservation_info]
  before_action :find_reservation_project, only: [:unpersisted_reservation_info]

  before_action :authorize, if: proc { @project.present? }
  before_action :authorize_global, if: proc { @project.nil? }

  # Create or update reservations
  #
  # Method: POST
  #
  # == API:
  #   {
  #     "reservations": [
  #       {
  #         # An ID of the reservation. If it's null or doesn't start with
  #         # a number -> new record will be created.
  #         "id": "1",
  #
  #         # Name (required)
  #         "name": "Name",
  #
  #         # Assignee id (required)
  #         "assigned_to_id": 1,
  #
  #         # Estimate hours (required)
  #         "estimated_hours": 1,
  #
  #         # Start date in http format (required)
  #         "start_date": "2018-01-01",
  #
  #         # Due date in http format (required)
  #         "due_date": "2018-01-31",
  #
  #         # Allocator
  #         "allocator": "Allocator",
  #
  #         # Resources (required)
  #         "resources": [
  #           { "date": "2018-01-01", "hours": 1 },
  #           { "date": "2018-01-02", "hours": 1 },
  #           { "date": "2018-01-03", "hours": 1 }
  #         ]
  #       }
  #     ]
  #   }
  #

  def new
    respond_to do |format|
      format.html {
        render layout: false
      }
    end
  end

  def bulk_update_or_create
    reservations = params.to_unsafe_hash.with_indifferent_access[:reservations]

    if !reservations.is_a?(Array)
      respond_to do |format|
        format.json { head 400 }
      end
      return
    end

    saved_reservations = []
    unsaved_reservations = []

    reservations.each do |res|
      id = res[:id].to_i

      if id > 0
        reservation = EasyGanttReservation.find_by(id: id)
      end
      reservation ||= EasyGanttReservation.new(author_id: User.current.id)
      reservation.original_id = res[:id]
      reservation.attributes = res.slice(:name, :assigned_to_id, :estimated_hours, :start_date, :due_date, :allocator, :description, :project_id)
      reservation.resources_attributes = res[:resources]

      if reservation.save
        saved_reservations << reservation
      else
        unsaved_reservations << reservation
      end
    end

    saved_json = []
    saved_reservations.each do |reservation|
      saved_json << {
        id: reservation.id,
        original_id: reservation.original_id,
      }
    end

    unsaved_json = []
    unsaved_reservations.each do |reservation|
      unsaved_json << {
        id: reservation.id,
        original_id: reservation.original_id,
        errors: reservation.errors
      }
    end

    render json: {
      saved: saved_json,
      unsaved: unsaved_json
    }
  end

  def unpersisted_reservation_info
  end

  # Destroy reservations
  #
  # Method: DELETE
  #
  # == API:
  #   {
  #     # Array of reservation ids
  #     "reservation_ids": []
  #   }
  #
  def bulk_destroy
    EasyGanttReservation.where(id: params[:reservation_ids]).destroy_all
    render_api_ok
  end

  private

  def find_reservation_project
    @project = @reservation.project
  end

  def build_new_from_params
    @reservation = EasyGanttReservation.new
    @reservation.safe_attributes = (params[:reservation] || {}).deep_dup
  end

end
